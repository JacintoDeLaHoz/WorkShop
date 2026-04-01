@IsTest
public class ClaimProcessorTest {

    class MockClaimRepository implements IClaimRepository {
        public List<Claim__c> claimsToReturn = new List<Claim__c>();
        public Boolean updateCalled = false;

        public List<Claim__c> getPendingClaims() {
            return claimsToReturn;
        }
        public void updateClaims(List<Claim__c> claims) {
            updateCalled = true;
        }
    }

    class MockNotifier implements INotifier {
        public Set<Id> notifiedIds = new Set<Id>();

        public void notifyStatusChange(Set<Id> claimIds, String status) {
            notifiedIds.addAll(claimIds);
        }
    }

    class MockValidator implements IRequirementValidator {
        public Boolean areRequirementsMet(Claim__c claim) {
            return true;
        }
    }

    class MockUSTaxStrategy implements ITaxStrategy {
        public Decimal calculateTax(Claim__c claim) {
            return 100.00;
        }
    }

    @IsTest
    static void testProcessAll_USLifeClaim_Success() {
        MockClaimRepository mockRepo = new MockClaimRepository();

        Claim__c fakeClaim = new Claim__c(
                Id = 'a00000000000001AAA',
                Amount__c = 1000,
                Country__c = 'US',
                Policy_Type__c = 'Life',
                Status__c = 'Pending'
        );
        mockRepo.claimsToReturn.add(fakeClaim);

        MockNotifier mockNotifier = new MockNotifier();
        MockValidator mockValidator = new MockValidator();
        MockUSTaxStrategy mockTax = new MockUSTaxStrategy();

        ClaimProcessor processor = new ClaimProcessor(mockRepo, mockTax, mockValidator, mockNotifier);

        processor.processAll();

        Assert.areEqual(100.00, fakeClaim.Tax_Amount__c, 'Tax should be calculated as 100.00');
        Assert.areEqual('Approved', fakeClaim.Status__c, 'Status should be updated to Approved');
        Assert.isTrue(mockRepo.updateCalled, 'Repository updateClaims() should have been called');
        Assert.isTrue(mockNotifier.notifiedIds.contains(fakeClaim.Id), 'Notifier should have been triggered');
    }
}
