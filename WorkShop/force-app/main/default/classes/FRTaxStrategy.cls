public class FRTaxStrategy implements ITaxStrategy {
    public Decimal calculateTax(Claim__c claim) {
        return claim.Amount__c * 0.20;
    }
}