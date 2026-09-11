/**
 * @description Factory de datos volumétricos y mixtos para la suite de estrés.
 *
 * El patrón de mezcla es DETERMINISTA (ver makeMixedOpportunities): dado el
 * índice de un registro, el test sabe exactamente qué comportamiento esperar.
 * Esto es lo que habilita las assertions profundas por registro.
 *
 * Patrón (módulo 20, con 10 Accounts => 2 Opportunities sin Account por Account):
 *   i % 20 en {0, 5, 10}  -> califica     (Closed Won, Amount >= 50.000)
 *   i % 20 en {2, 7}      -> monto bajo   (Closed Won, Amount < 50.000)
 *   i % 20 en {3, 8, 13}  -> etapa abierta (Prospecting, Amount >= 50.000)
 *   i % 20 en {4, 9}      -> Amount nulo  (Closed Won)
 *   resto                 -> neutros      (Negotiation, Amount bajo)
 *   i % 10 == 8 o 9       -> sin Account  (los 2 últimos de cada Account; nunca califican)
 * @group Stress Testing
 */
@IsTest
public class OpportunityTestDataFactory {

    /**
     * @description Crea e inserta Accounts de prueba sin Rating.
     * @param count Número de Accounts a crear
     * @return Accounts insertados (con Id)
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Stress Account ' + i));
        }
        insert accounts;
        return accounts;
    }

    /**
     * @description Crea oppsPerAccount Opportunities por Account con el patrón
     *              mixto (sin insertar). Requiere oppsPerAccount >= 10 para que
     *              el patrón completo (incluidos los sin Account) aparezca.
     * @param accounts       Accounts padre
     * @param oppsPerAccount Opportunities por Account (total = accounts * este valor)
     * @return Opportunities en memoria, en orden determinista
     */
    public static List<Opportunity> makeMixedOpportunities(List<Account> accounts, Integer oppsPerAccount) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < oppsPerAccount; i++) {
                opps.add(buildMixedOpportunity(acc.Id, i));
            }
        }
        return opps;
    }

    /**
     * @description Versión abierta: mismas reglas de monto, pero todos en etapa
     *              Negotiation. Usada por el test de transición de etapa
     *              (update masivo a Closed Won).
     * @param accounts       Accounts padre
     * @param oppsPerAccount Opportunities por Account
     * @return Opportunities abiertas en memoria, en orden determinista
     */
    public static List<Opportunity> makeOpenOpportunities(List<Account> accounts, Integer oppsPerAccount) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < oppsPerAccount; i++) {
                Opportunity o = buildMixedOpportunity(acc.Id, i);
                o.StageName = 'Negotiation';
                opps.add(o);
            }
        }
        return opps;
    }

    /**
     * @description Predicción del factory: ¿el registro i-ésimo cumple la regla
     *              de alto valor? Habilita las assertions profundas por registro.
     * @param index      Posición del registro dentro de su Account (0-based)
     * @param hasAccount Si el registro tiene Account (ver hasAccountByIndex)
     * @return true si se espera que califique
     */
    public static Boolean isExpectedQualifier(Integer index, Boolean hasAccount) {
        return hasAccount && Math.mod(index, 20) == 0
            || hasAccount && Math.mod(index, 20) == 5
            || hasAccount && Math.mod(index, 20) == 10;
    }

    /**
     * @description Predicción para el escenario de TRANSICIÓN: tras un update
     *              masivo a Closed Won, también califican los registros de etapa
     *              abierta con monto alto (slots 3, 8, 13). Solo quedan fuera
     *              los de monto bajo (2, 7), Amount nulo (4, 9) y neutros.
     * @param index      Posición del registro dentro de su Account (0-based)
     * @param hasAccount Si el registro tiene Account (ver hasAccountByIndex)
     * @return true si se espera que califique tras la transición a Closed Won
     */
    public static Boolean isExpectedQualifierAfterTransition(Integer index, Boolean hasAccount) {
        Integer slot = Math.mod(index, 20);
        return hasAccount && (slot == 0 || slot == 5 || slot == 10
            || slot == 3 || slot == 8 || slot == 13);
    }

    /**
     * @description Predicción del factory: ¿el registro i-ésimo tiene Account?
     * @param index Posición del registro dentro de su Account (0-based)
     * @return true si el patrón le asigna Account
     */
    public static Boolean hasAccountByIndex(Integer index) {
        return Math.mod(index, 10) < 8;
    }

    /**
     * @description Construye una Opportunity según el patrón mixto.
     * @param accountId Account padre (se ignora si el patrón indica sin Account)
     * @param i         Posición del registro dentro de su Account (0-based)
     * @return Opportunity en memoria
     */
    private static Opportunity buildMixedOpportunity(Id accountId, Integer i) {
        Integer slot = Math.mod(i, 20);
        Boolean hasAccount = hasAccountByIndex(i);

        Opportunity o = new Opportunity(
            AccountId = hasAccount ? accountId : null,
            Name = 'Stress Opp ' + i,
            CloseDate = Date.today().addDays(30),
            Amount = 10000,
            StageName = 'Negotiation'
        );

        if (slot == 0 || slot == 5 || slot == 10) {
            o.StageName = 'Closed Won';
            o.Amount = 60000;
        } else if (slot == 2 || slot == 7) {
            o.StageName = 'Closed Won';
            o.Amount = 49999;
        } else if (slot == 3 || slot == 8 || slot == 13) {
            o.StageName = 'Prospecting';
            o.Amount = 80000;
        } else if (slot == 4 || slot == 9) {
            o.StageName = 'Closed Won';
            o.Amount = null;
        }
        return o;
    }
}
