public class ClaimProcessor {

    public static void processAll() {

        List<Claim__c> claims = [
                SELECT Id, Amount__c, Country__c, Policy_Type__c,
                (SELECT Id, Status__c FROM Requirements__r)
                FROM Claim__c
                WHERE Status__c = 'Pending'
        ];

        for (Claim__c c : claims) {

            if (c.Country__c == 'US') {
                if (c.Policy_Type__c == 'Life') {
                    c.Tax_Amount__c = c.Amount__c * 0.10;
                } else {
                    c.Tax_Amount__c = c.Amount__c * 0.05;
                }
            } else if (c.Country__c == 'FR') {
                c.Tax_Amount__c = c.Amount__c * 0.20;
            }

            Boolean allMet = true;
            for (Requirement__r req : c.Requirements__r) {
                if (req.Status__c != 'Completed') {
                    allMet = false;
                }
            }

            if (allMet) {
                c.Status__c = 'Approved';

                ExternalService.notifyStatus(c.Id, 'Approved');

                update c;
            }
        }
    }
}