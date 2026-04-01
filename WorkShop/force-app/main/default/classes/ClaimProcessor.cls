public class ClaimProcessor {

    public ClaimProcessor(
            ITaxStrategy taxFactory,
            IRequirementValidator validator,
            INotifier notifier,
            IClaimRepository repo
    ) {
        this.taxFactory = taxFactory;
        this.validator = validator;
        this.notifier = notifier;
    }

    public void processAll() {
        // RED PHASE: No logic here yet.
    }

}