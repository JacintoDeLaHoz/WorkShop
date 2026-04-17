public class ClaimProcessor {

    private ITaxStrategyFactory taxFactory;
    private IRequirementValidator validator;
    private INotifier notifier;
    private IClaimRepository repo;

    public ClaimProcessor(
            ITaxStrategyFactory taxFactory,
            IRequirementValidator validator,
            INotifier notifier,
            IClaimRepository repo
    ) {
        this.taxFactory = taxFactory;
        this.validator = validator;
        this.notifier = notifier;
        this.repo = repo;
    }

    public void processAll() {
        List<Claim__c> claims = repo.getPendingClaims();

        List<Claim__c> claimsToUpdate = new List<Claim__c>();
        Set<Id> approvedClaimIds = new Set<Id>();

        evaluateClaims(claims, claimsToUpdate, approvedClaimIds);

        finalizeProcessing(claimsToUpdate, approvedClaimIds);
    }


    private void evaluateClaims(List<Claim__c> claims, List<Claim__c> claimsToUpdate, Set<Id> approvedIds) {
        for (Claim__c c : claims) {
            applyTax(c);
            validateAndApprove(c, approvedIds);
            claimsToUpdate.add(c);
        }
    }

    private void applyTax(Claim__c c) {
        ITaxStrategy strategy = taxFactory.getStrategy(c.Country__c);
        if (strategy != null) {
            c.Tax_Amount__c = strategy.calculateTax(c);
        }
    }

    private void validateAndApprove(Claim__c c, Set<Id> approvedIds) {
        if (validator.areRequirementsMet(c)) {
            c.Status__c = 'Approved';
            approvedIds.add(c.Id);
        }
    }

    private void finalizeProcessing(List<Claim__c> claimsToUpdate, Set<Id> approvedIds) {
        if (!claimsToUpdate.isEmpty()) {
            repo.updateClaims(claimsToUpdate);
        }

        if (!approvedIds.isEmpty()) {
            notifier.notifyStatusChange(approvedIds, 'Approved');
        }
}