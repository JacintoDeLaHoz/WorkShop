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

        for (Claim__c c : claims) {

            ITaxStrategy strategy = taxFactory.getStrategy(c.Country__c);
            if (strategy != null) {
                c.Tax_Amount__c = strategy.calculateTax(c);
            }

            if (validator.areRequirementsMet(c)) {
                c.Status__c = 'Approved';
                approvedClaimIds.add(c.Id);
            }

            claimsToUpdate.add(c);
        }

        if (!claimsToUpdate.isEmpty()) {
            repo.updateClaims(claimsToUpdate);
        }

        if (!approvedClaimIds.isEmpty()) {
            notifier.notifyStatusChange(approvedClaimIds, 'Approved');
        }
    }

}