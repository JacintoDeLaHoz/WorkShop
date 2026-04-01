public interface IClaimRepository {
    List<Claim__c> getPendingClaims();
    void updateClaims(List<Claim__c> claims);
}