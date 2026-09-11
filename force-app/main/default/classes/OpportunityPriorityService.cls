/**
 * @description Servicio de priorización de Opportunities de alto valor.
 *              Reglas de negocio (ver docs/ESTRATEGIA-TESTING.md):
 *              R1 - Opportunity en Closed Won con Amount >= 50.000 => Account.Rating = 'Hot'
 *              R2 - Cada Opportunity de alto valor recibe exactamente UN Task de
 *                   seguimiento (la creación debe ser idempotente: reprocesar
 *                   nunca duplica)
 *              R3 - Todo lo demás queda intacto (etapas abiertas, monto bajo,
 *                   Amount nulo, Opportunity sin Account)
 *              NOTA TDD: esta clase nace como STUB (fase RED). La implementación
 *              real bulkificada se escribe en la fase GREEN, guiada por
 *              OpportunityStressTest.
 */
public with sharing class OpportunityPriorityService {

    public static final Decimal HIGH_VALUE_THRESHOLD = 50000;
    public static final String HOT_RATING = 'Hot';
    public static final String FOLLOW_UP_SUBJECT = 'Follow up on high-value deal';

    /**
     * @description Punto de entrada invocado por el trigger con los registros de
     *              la transacción. STUB (fase RED): sin lógica todavía.
     * @param newList Opportunities de Trigger.new
     * @param oldMap  Trigger.oldMap (null en insert)
     */
    public static void process(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        // STUB (fase RED): sin lógica todavía.
    }

    /**
     * @description Reprocesa registros ya persistidos (usado por los tests de
     *              idempotencia y de consumo de recursos). STUB (fase RED).
     * @param opportunityIds Ids de las Opportunities a reprocesar
     */
    public static void processByIds(Set<Id> opportunityIds) {
        // STUB (fase RED): sin lógica todavía.
    }
}
