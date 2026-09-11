/**
 * @description Suite de stress testing para OpportunityPriorityService, diseñada
 *              según la Masterclass Mes 5 (Performance & Stress Testing Strategy):
 *              1. Bulk de 200 registros               -> tests 1, 2 y 5
 *              2. Múltiples transacciones/ejecuciones -> tests 3 y 4
 *              3. Detección de riesgos de límites     -> test 5
 *              4. Validación de consumo de recursos   -> test 5 (Limits.*)
 *              5. Escenarios extremos                 -> tests 1, 4 y 6
 *              6. Assertions profundas                -> OpportunityStressAssertions
 *              7. Riesgos futuros                     -> evidencia de tests 3-5,
 *                 análisis en docs/ESTRATEGIA-TESTING.md
 *              Todas las pruebas ejercitan el trigger REAL vía DML, igual que
 *              Producción. Las assertions de negocio viven fuera de esta clase
 *              (OpportunityStressAssertions) por regla del proyecto.
 * @group Stress Testing
 */
@IsTest
private class OpportunityStressTest {

    /**
     * @description Bulk 200 con datos mixtos en una sola transacción (insert).
     *              Cubre objetivos 1, 5 y 6.
     */
    @IsTest
    static void bulk200_mixedInsert_correctlyPrioritizes() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeMixedOpportunities(accounts, 20);
        Assert.areEqual(200, opps.size(), 'Setup: el escenario debe tener 200 registros');

        Test.startTest();
        insert opps;
        Test.stopTest();

        OpportunityStressAssertions.assertAccountsRatedCorrectly(accounts, opps);
        OpportunityStressAssertions.assertTasksMatchQualifiers(opps, 'bulk 200 insert');
    }

    /**
     * @description Bulk 200 por transición de etapa (update masivo a Closed Won).
     *              Cubre objetivos 1, 5 y 6.
     */
    @IsTest
    static void bulk200_stageTransitionUpdate_correctlyPrioritizes() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeOpenOpportunities(accounts, 20);
        insert opps;

        Assert.areEqual(0, [SELECT COUNT() FROM Task WHERE WhatId IN :opps],
            'Precondición: Opportunities abiertas no generan Tasks');

        for (Opportunity o : opps) {
            o.StageName = 'Closed Won';
        }

        Test.startTest();
        update opps;
        Test.stopTest();

        // Tras la transición, los abiertos de monto alto (slots 3/8/13) también
        // califican: Closed Won + Amount >= umbral es la regla, sin importar la
        // etapa original. La predicción usa la variante post-transición.
        OpportunityStressAssertions.assertAccountsRatedCorrectly(accounts, opps, true);
        OpportunityStressAssertions.assertTasksMatchQualifiers(opps, 'bulk 200 update', true);
    }

    /**
     * @description Múltiples transacciones: los mismos 200 en 4 tandas de 50.
     *              El estado final debe ser idéntico al bulk único: sin
     *              duplicados ni fuga de estado estático. Cubre objetivo 2.
     */
    @IsTest
    static void multipleTransactions_4x50_noStateLeakage() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeMixedOpportunities(accounts, 20);

        Test.startTest();
        for (Integer chunk = 0; chunk < 4; chunk++) {
            List<Opportunity> slice = new List<Opportunity>();
            for (Integer i = chunk * 50; i < (chunk + 1) * 50; i++) {
                slice.add(opps[i]);
            }
            insert slice;
        }
        Test.stopTest();

        OpportunityStressAssertions.assertAccountsRatedCorrectly(accounts, opps);
        OpportunityStressAssertions.assertTasksMatchQualifiers(opps, '4 transacciones de 50');
    }

    /**
     * @description Ejecución repetida: reprocesar NUNCA duplica Tasks. La
     *              deduplicación debe ser por datos, no por variables estáticas.
     *              Cubre objetivos 2, 5 y 6.
     */
    @IsTest
    static void repeatedExecution_neverDuplicatesTasks() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeMixedOpportunities(accounts, 20);
        insert opps;

        Integer tasksAfterFirstRun = [SELECT COUNT() FROM Task WHERE WhatId IN :opps];
        Assert.isTrue(tasksAfterFirstRun > 0, 'Setup: el primer procesamiento debió crear Tasks');

        Test.startTest();
        OpportunityPriorityService.processByIds(new Map<Id, Opportunity>(opps).keySet());
        OpportunityPriorityService.processByIds(new Map<Id, Opportunity>(opps).keySet());
        Test.stopTest();

        Integer tasksAfterRerun = [SELECT COUNT() FROM Task WHERE WhatId IN :opps];
        Assert.areEqual(tasksAfterFirstRun, tasksAfterRerun,
            'Reprocesar no debe duplicar Tasks de seguimiento');

        OpportunityStressAssertions.assertAccountsRatedCorrectly(accounts, opps);
    }

    /**
     * @description Consumo de recursos con 50 registros. Dos métodos independientes
     *              (startTest/stopTest es una vez por test); además demuestran que
     *              el consumo es estable entre ejecuciones. Cubre objetivos 3 y 4.
     */
    @IsTest
    static void resourceConsumption_at50Records_withinBudget() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeMixedOpportunities(accounts, 20);
        insert opps;

        Set<Id> ids50 = new Set<Id>();
        for (Integer i = 0; i < 50; i++) {
            ids50.add(opps[i].Id);
        }

        Test.startTest();
        Integer qBefore = Limits.getQueries();
        Integer dBefore = Limits.getDmlStatements();
        Integer cBefore = Limits.getCpuTime();
        OpportunityPriorityService.processByIds(ids50);
        Integer queries = Limits.getQueries() - qBefore;
        Integer dml = Limits.getDmlStatements() - dBefore;
        Integer cpu = Limits.getCpuTime() - cBefore;
        Test.stopTest();

        OpportunityStressAssertions.assertWithinBudget(queries, dml, cpu, 50);
    }

    /**
     * @description Consumo de recursos con 200 registros (peor caso del trigger).
     *              Mismo budget que con 50: el consumo debe ser plano, no
     *              proporcional al volumen. Cubre objetivos 1, 3 y 4.
     */
    @IsTest
    static void resourceConsumption_at200Records_withinBudget() {
        List<Account> accounts = OpportunityTestDataFactory.createAccounts(10);
        List<Opportunity> opps = OpportunityTestDataFactory.makeMixedOpportunities(accounts, 20);
        insert opps;

        Test.startTest();
        Integer qBefore = Limits.getQueries();
        Integer dBefore = Limits.getDmlStatements();
        Integer cBefore = Limits.getCpuTime();
        OpportunityPriorityService.processByIds(new Map<Id, Opportunity>(opps).keySet());
        Integer queries = Limits.getQueries() - qBefore;
        Integer dml = Limits.getDmlStatements() - dBefore;
        Integer cpu = Limits.getCpuTime() - cBefore;
        Test.stopTest();

        OpportunityStressAssertions.assertWithinBudget(queries, dml, cpu, 200);
    }

    /**
     * @description Edge cases y negativos: los datos que NO cumplen la regla quedan
     *              intactos; un update irrelevante no genera trabajo. Cubre
     *              objetivos 5 y 6.
     */
    @IsTest
    static void edgeCases_andNegatives_leaveDataUntouched() {
        Account acc = OpportunityTestDataFactory.createAccounts(1)[0];

        Opportunity below = new Opportunity(
            Name = 'Below threshold', AccountId = acc.Id, StageName = 'Closed Won',
            Amount = 49999.99, CloseDate = Date.today());
        Opportunity noAccount = new Opportunity(
            Name = 'No account', StageName = 'Closed Won',
            Amount = 200000, CloseDate = Date.today());
        Opportunity nullAmount = new Opportunity(
            Name = 'Null amount', AccountId = acc.Id, StageName = 'Closed Won',
            Amount = null, CloseDate = Date.today());
        Opportunity open = new Opportunity(
            Name = 'Open high value', AccountId = acc.Id, StageName = 'Prospecting',
            Amount = 500000, CloseDate = Date.today());
        Opportunity qualifier = new Opportunity(
            Name = 'Qualifier', AccountId = acc.Id, StageName = 'Closed Won',
            Amount = 60000, CloseDate = Date.today());
        insert new List<Opportunity>{ below, noAccount, nullAmount, open, qualifier };

        Test.startTest();
        qualifier.Description = 'Campo sin relevancia de negocio';
        update qualifier;
        Test.stopTest();

        Account accAfter = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(OpportunityPriorityService.HOT_RATING, accAfter.Rating,
            'El Account con un calificador debe quedar Hot');

        Map<Id, List<Task>> tasksByOpp = new Map<Id, List<Task>>();
        for (Task t : [SELECT WhatId FROM Task WHERE WhatId IN
                :new Set<Id>{ below.Id, noAccount.Id, nullAmount.Id, open.Id, qualifier.Id }]) {
            if (!tasksByOpp.containsKey(t.WhatId)) {
                tasksByOpp.put(t.WhatId, new List<Task>());
            }
            tasksByOpp.get(t.WhatId).add(t);
        }

        Assert.areEqual(1, tasksByOpp.containsKey(qualifier.Id) ? tasksByOpp.get(qualifier.Id).size() : 0,
            'El calificador tiene exactamente 1 Task (el update irrelevante no duplicó)');
        Assert.isNull(tasksByOpp.get(below.Id), 'Monto bajo no genera Task');
        Assert.isNull(tasksByOpp.get(noAccount.Id), 'Sin Account no genera Task');
        Assert.isNull(tasksByOpp.get(nullAmount.Id), 'Amount nulo no genera Task');
        Assert.isNull(tasksByOpp.get(open.Id), 'Etapa abierta no genera Task');
    }
}
