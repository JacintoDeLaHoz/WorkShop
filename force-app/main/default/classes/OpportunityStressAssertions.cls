/**
 * @description Assertions profundas reutilizables para la suite de estrés de
 *              OpportunityPriorityService. Los test methods solo orquestan; las
 *              assertions de negocio se reutilizan entre escenarios.
 * @group Stress Testing
 */
@IsTest
public class OpportunityStressAssertions {

    /** @description Techo defensivo de SOQL/DML por ejecución (límite síncrono: 100/150). */
    public static final Integer LIMIT_BUDGET = 20;

    /**
     * @description Verifica Account por Account: Rating = 'Hot' si y solo si tiene
     *              al menos una Opportunity calificadora según el patrón determinista
     *              del factory; en caso contrario, el Rating debió permanecer intacto.
     * @param accounts Accounts creados por el factory (mismo orden)
     * @param opps     Opportunities del escenario (mismo orden de inserción)
     */
    public static void assertAccountsRatedCorrectly(List<Account> accounts, List<Opportunity> opps) {
        assertAccountsRatedCorrectly(accounts, opps, false);
    }

    /**
     * @description Sobrecarga para el escenario de transición de etapa: usa la
     *              predicción post-transición (los abiertos de monto alto pasan
     *              a calificar cuando el update los vuelve Closed Won.
     * @param accounts       Accounts creados por el factory (mismo orden)
     * @param opps           Opportunities del escenario
     * @param afterTransition true si el escenario actualizó todo a Closed Won
     */
    public static void assertAccountsRatedCorrectly(List<Account> accounts, List<Opportunity> opps, Boolean afterTransition) {
        Set<Id> shouldBeHot = new Set<Id>();
        Integer perAccount = opps.size() / accounts.size();
        for (Integer a = 0; a < accounts.size(); a++) {
            for (Integer i = 0; i < perAccount; i++) {
                Boolean hasAccount = OpportunityTestDataFactory.hasAccountByIndex(i);
                Boolean expected = afterTransition
                    ? OpportunityTestDataFactory.isExpectedQualifierAfterTransition(i, hasAccount)
                    : OpportunityTestDataFactory.isExpectedQualifier(i, hasAccount);
                if (expected) {
                    shouldBeHot.add(accounts[a].Id);
                    break;
                }
            }
        }

        for (Account acc : [SELECT Id, Rating FROM Account WHERE Id IN :accounts]) {
            if (shouldBeHot.contains(acc.Id)) {
                Assert.areEqual(OpportunityPriorityService.HOT_RATING, acc.Rating,
                    'Account ' + acc.Id + ' tiene calificadores: debe quedar Hot');
            } else {
                Assert.isNull(acc.Rating,
                    'Account ' + acc.Id + ' sin calificadores: no debió modificarse');
            }
        }
    }

    /**
     * @description Verifica Opportunity por Opportunity: existe exactamente UN Task
     *              con los campos correctos si y solo si el registro califica; los
     *              demás no tienen ninguno. No basta con contar: se valida WhatId,
     *              Subject y OwnerId (assertions profundas, Masterclass p.18-19).
     * @param opps        Opportunities del escenario (10 Accounts x N por Account)
     * @param context     Nombre del escenario para mensajes de fallo legibles
     */
    public static void assertTasksMatchQualifiers(List<Opportunity> opps, String context) {
        assertTasksMatchQualifiers(opps, context, false);
    }

    /**
     * @description Sobrecarga para el escenario de transición de etapa.
     * @param opps           Opportunities del escenario (10 Accounts x N)
     * @param context        Nombre del escenario para mensajes de fallo legibles
     * @param afterTransition true si el escenario actualizó todo a Closed Won
     */
    public static void assertTasksMatchQualifiers(List<Opportunity> opps, String context, Boolean afterTransition) {
        Map<Id, List<Task>> tasksByOpp = new Map<Id, List<Task>>();
        for (Task t : [SELECT WhatId, Subject, OwnerId FROM Task WHERE WhatId IN :new Map<Id, Opportunity>(opps).keySet()]) {
            if (!tasksByOpp.containsKey(t.WhatId)) {
                tasksByOpp.put(t.WhatId, new List<Task>());
            }
            tasksByOpp.get(t.WhatId).add(t);
        }

        Integer perAccount = opps.size() / 10;
        for (Integer idx = 0; idx < opps.size(); idx++) {
            Integer i = Math.mod(idx, perAccount);
            Boolean hasAccount = OpportunityTestDataFactory.hasAccountByIndex(i);
            Boolean expected = afterTransition
                ? OpportunityTestDataFactory.isExpectedQualifierAfterTransition(i, hasAccount)
                : OpportunityTestDataFactory.isExpectedQualifier(i, hasAccount);
            Opportunity o = opps[idx];
            List<Task> tasks = tasksByOpp.get(o.Id);

            if (expected) {
                Assert.areEqual(1, tasks == null ? 0 : tasks.size(),
                    context + ': la Opportunity calificadora ' + o.Name + ' debe tener exactamente 1 Task');
                Assert.areEqual(OpportunityPriorityService.FOLLOW_UP_SUBJECT, tasks[0].Subject,
                    context + ': Subject incorrecto para ' + o.Name);
                Assert.areEqual(UserInfo.getUserId(), tasks[0].OwnerId,
                    context + ': el Task debe pertenecer al dueño de la Opportunity ' + o.Name);
            } else {
                Assert.isNull(tasks,
                    context + ': la Opportunity no calificadora ' + o.Name + ' no debe tener Tasks');
            }
        }
    }

    /**
     * @description Techo absoluto defensivo (riesgo de límites). Si el consumo a 50
     *              y a 200 registros cabe en el mismo budget, el consumo es plano
     *              respecto al volumen = comportamiento escalable (Masterclass p.16).
     * @param queries     SOQL consumidos en la ventana medida
     * @param dml         DML statements consumidos en la ventana medida
     * @param cpu         CPU time (ms) consumido en la ventana medida
     * @param recordCount Tamaño del lote procesado (para el mensaje de fallo)
     */
    public static void assertWithinBudget(Integer queries, Integer dml, Integer cpu, Integer recordCount) {
        Assert.isTrue(queries < LIMIT_BUDGET,
            'SOQL fuera de budget con ' + recordCount + ' registros: ' + queries);
        Assert.isTrue(dml < LIMIT_BUDGET,
            'DML fuera de budget con ' + recordCount + ' registros: ' + dml);
        Assert.isTrue(cpu < 5000,
            'CPU fuera de budget con ' + recordCount + ' registros: ' + cpu + ' ms');
    }
}
