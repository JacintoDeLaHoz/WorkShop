/**
 *
 */

@IsTest
private class LeadAssigmentServiceTest {

    @TestSetup
    static void makeData(){
        Group group = new Group(Name = 'Unassigned_Leads', Type = 'Queue');
        insert group;
        insert new QueueSobject(QueueId = group.Id, SobjectType = 'Lead');
    }

    @IsTest
    static void assignLead_givenMissingTerritory_escalatesToQueue() {
        Lead lead = new Lead(
                LastName = 'Test',
                Company = 'Acme Corp',
                Industry = 'Technology'
                //State intentionally blank = no territory
        );
        insert lead;

        LeadAssigmentService service = new LeadAssigmentService();
        service.assignLead(lead);

        Lead insertedLead = [SELECT Id FROM Lead WHERE Id = :lead.Id];
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('00G'),
                'Lead with no territory must be escalated to a queue');
    }

    @IsTest
    static void assignLead_givenMissingIndustry_escalatesToQueue(){
        Lead lead = new Lead(
                LastName = 'Test',
                Company = 'Acme Corp',
                State = 'CA'
                //Industry intentionally blank
        );
        insert lead;

        LeadAssigmentService service = new LeadAssigmentService();
        service.assignLead(lead);

        Lead insertedLead = [SELECT Id FROM Lead WHERE Id = :lead.Id];
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('00G'),
                'Lead with no Industry must be escalated to a queue');
    }

    @IsTest
    static void assignLead_givenRepAvailable_assignRepAndSetsStatusWorking(){
        Lead lead = new Lead(
                LastName = 'Test',
                Company = 'Acme Corp',
                State = 'CA',
                Industry = 'Technology'
        );
        insert lead;

        LeadAssigmentService service = new LeadAssigmentService(
                new FakeGatewaySuccess()
        );

        LeadAssigmentService.AssigmentResult result = service.assignLead(lead);

        Assert.isTrue(result.wasAssigned,
                'result must report wasAssigned equal to true');
        Lead insertedLead = [SELECT Id FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Working', insertedLead.Status,
                'Status must be working after assigment');
        Assert.isTrue(String.valueOf(insertedLead.OwnerId).startsWith('005'),
                'Owner must be an user');
    }
}

public class FakeGateway implements IRoutingGateway{
    public RoutingResult findBestRep(String string, String i, Integer l){
        return RoutingResult.assigned('00500000000001AAA', 'Jane Doe');
    }
}