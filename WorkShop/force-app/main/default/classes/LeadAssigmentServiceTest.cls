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
}