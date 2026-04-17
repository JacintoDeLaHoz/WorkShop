@IsTest
public class ClaimProcessorTest {

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

        ClaimProcessor processor = new ClaimProcessor(
                new MockTaxFactory(),
                new MockValidator(),
                new MockNotifier(),
                mockRepo
        );

        Test.startTest();
        processor.processAll();
        Test.stopTest();

        Assert.areEqual(100.00, fakeClaim.Tax_Amount__c, 'Tax should be 100.00');
        Assert.areEqual('Approved', fakeClaim.Status__c, 'Status should be Approved');
        Assert.isTrue(mockRepo.updateCalled, 'updateClaims() should have been called');
        Assert.isTrue(mockNotifier.notifiedIds.contains(fakeClaim.Id), 'Notifier should fire');
    }
}