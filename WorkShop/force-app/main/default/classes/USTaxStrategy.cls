public class USTaxStrategy implements ITaxStrategy {
    public Decimal calculateTax(Claim__c claim) {
        if (claim.Policy_Type__c == 'Life') {
            return claim.Amount__c * 0.10;
        }
        return claim.Amount__c * 0.05;
    }
}
