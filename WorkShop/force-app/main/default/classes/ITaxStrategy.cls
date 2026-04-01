public interface ITaxStrategy {
    Decimal calculateTax(Claim__c claim);
}