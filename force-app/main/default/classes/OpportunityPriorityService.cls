/**
 * @description Servicio de priorización de Opportunities de alto valor.
 *              R1 - Opportunity en Closed Won con Amount >= 50.000 => Account.Rating = 'Hot'
 *              R2 - Cada Opportunity de alto valor recibe exactamente UN Task de
 *                   seguimiento (la creación debe ser idempotente: reprocesar
 *                   nunca duplica)
 *              R3 - Todo lo demás queda intacto (etapas abiertas, monto bajo,
 *                   Amount nulo, Opportunity sin Account)
 *              Diseño bulkificado (fase GREEN de TDD): sin SOQL/DML en loops,
 *              trabajo en colecciones y deduplicación por datos (no por
 *              variables estáticas), por lo que soporta reejecuciones y
 *              múltiples transacciones.
 */
public with sharing class OpportunityPriorityService {

    public static final Decimal HIGH_VALUE_THRESHOLD = 50000;
    public static final String HOT_RATING = 'Hot';
    public static final String FOLLOW_UP_SUBJECT = 'Follow up on high-value deal';

    /**
     * @description Punto de entrada invocado por el trigger con los registros de
     *              la transacción.
     * @param newList Opportunities de Trigger.new
     * @param oldMap  Trigger.oldMap (null en insert)
     */
    public static void process(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (newList == null || newList.isEmpty()) {
            return;
        }
        processInternal(newList);
    }

    /**
     * @description Reprocesa registros ya persistidos (usado por los tests de
     *              idempotencia y de consumo de recursos, y disponible para
     *              batches/integraciones).
     * @param opportunityIds Ids de las Opportunities a reprocesar
     */
    public static void processByIds(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        processInternal([
            SELECT Id, StageName, Amount, AccountId, OwnerId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    /**
     * @description Núcleo bulkificado: una sola pasada sobre la colección, una
     *              query de Tasks existentes y como máximo dos DML (update de
     *              Accounts + insert de Tasks), sin importar el volumen.
     * @param opps Opportunities a evaluar (ya consultadas con todos los campos)
     */
    private static void processInternal(List<Opportunity> opps) {
        List<Opportunity> highValue = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o: opps) {
            if (isHighValue(o)) {
                highValue.add(o);
                accountIds.add(o.AccountId);
            }
        }
        if (highValue.isEmpty()) {
            return;
        }

        // R1 - marcar Accounts como Hot
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId: accountIds) {
            accountsToUpdate.add(new Account(Id = accountId, Rating = HOT_RATING));
        }
        update accountsToUpdate;

        // R2 - Tasks de seguimiento idempotentes: la deduplicación se basa en
        // datos existentes (query), no en estado estático, así es segura en
        // reejecuciones y entre transacciones.
        Map<Id, Boolean> hasFollowUp = new Map<Id, Boolean>();
        for (Task t : [
            SELECT WhatId
            FROM Task
            WHERE WhatId IN :new Map<Id, Opportunity>(highValue).keySet()
            AND Subject = :FOLLOW_UP_SUBJECT
        ]) {
            hasFollowUp.put(t.WhatId, true);
        }

        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity o: highValue) {
            if (!hasFollowUp.containsKey(o.Id)) {
                tasksToInsert.add(new Task(
                    WhatId = o.Id,
                    OwnerId = o.OwnerId,
                    Subject = FOLLOW_UP_SUBJECT,
                    Status = 'Not Started',
                    Priority = 'High',
                    ActivityDate = Date.today().addDays(3)
                ));
            }
        }
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    /**
     * @description Regla de alto valor: Closed Won, monto >= umbral y con Account (R3).
     * @param o Opportunity a evaluar
     * @return true si cumple la regla R1/R2
     */
    private static Boolean isHighValue(Opportunity o) {
        return o.StageName == 'Closed Won'
            && o.Amount != null
            && o.Amount >= HIGH_VALUE_THRESHOLD
            && o.AccountId != null;
    }
}
