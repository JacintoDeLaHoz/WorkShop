@IsTest
public class MockClaimRepository implements IClaimRepository {
    public List<Claim__c> claimsToReturn = new List<Claim__c>();
    public Boolean updateCalled = false;

    public List<Claim__c> getPendingClaims() {
        return claimsToReturn;
    }
    public void updateClaims(List<Claim__c> claims) {
        updateCalled = true;
    }
}