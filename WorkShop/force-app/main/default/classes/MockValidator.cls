public class MockValidator implements IRequirementValidator {
    public Boolean validate(Claim__c claim) {
        return false;
    }
}