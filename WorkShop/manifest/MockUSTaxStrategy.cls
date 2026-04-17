@IsTest
public class MockUSTaxStrategy implements ITaxStrategy {
    public Decimal calculateTax(Claim__c claim) {
        return 100.00;
    }
}