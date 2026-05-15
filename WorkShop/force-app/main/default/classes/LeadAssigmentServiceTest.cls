@IsTest
private class LeadAssigmentServiceTest {

    @TestSetup
    static void makeData(){
        TestDataFactory.aQueue()
                .named('Unassigned_Leads')
                .save();
    }

    @IsTest
    static void assignLead_givenMissingTerritory_escalatesToQueue() {
        Lead lead = TestDataFactory.aLead().inIndustry('Technology').withNoTerritory().save();

        LeadAssigmentService service = makeService(
                new LeadAssignmentMocks.RoutingAlwaysSucceeds('005000000000001AAA', 'Jane Doe')
        );

        Lead insertedLead = [SELECT Id, OwnerId, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('00G'),
                'Lead with no territory must be escalated to a queue');
    }

    @IsTest
    static void assignLead_givenMissingIndustry_escalatesToQueue(){
        Lead lead = TestDataFactory.aLead().fromTerritory('CA').withNoIndustry() .save();

        LeadAssigmentService service = makeService(
                new LeadAssignmentMocks.RoutingAlwaysSucceeds('005000000000001AAA', 'Jane Doe')
        );

        Lead insertedLead = [SELECT Id, OwnerId, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('00G'),
                'Lead with no Industry must be escalated to a queue');
    }

    @IsTest
    static void assignLead_givenRepAvailable_assignRepAndSetsStatusWorking(){
        Lead lead = TestDataFactory.aLead().fromTerritory('CA').inIndustry('Technology').save();

        LeadAssigmentService service = makeService(
                new LeadAssignmentMocks.RoutingAlwaysSucceeds('005000000000001AAA', 'Jane Doe')
        );

        AssignmentResult result = service.assignLead(lead);

        Assert.isTrue(result.wasAssigned,
                'result must report wasAssigned equal to true');
        Lead insertedLead = [SELECT Id, OwnerId, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.areEqual('Working', insertedLead.Status,
                'Status must be working after assigment');
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('005'),
                'Owner must be an user');
    }

    private static LeadAssigmentService makeService(IRoutingGateway gateway) {
        return new LeadAssigmentService(gateway);
    }
}
