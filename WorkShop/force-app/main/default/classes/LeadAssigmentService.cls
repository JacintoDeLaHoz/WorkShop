public with sharing class LeadAssigmentService {

    private final IRoutingGateway gateway;

    public LeadAssigmentService(){
        this.gateway = new ExternalRoutingGateway();
    }

    @TestVisible
    private LeadAssigmentService(IRoutingGateway gateway){
        this.gateway = gateway;
    }

    public AssignmentResult assignLead(Lead lead){
        Group queue = [
                SELECT Id
                FROM Group
                WHERE Name = 'Unassigned_Leads'
                AND Type = 'Queue'
                LIMIT 1
        ];

        if (String.isBlank(lead.State) || String.isBlank(lead.Industry)){
            lead.OwnerId = queue.Id;
            lead.Status = 'Open';
            update lead;
            return AssignmentResult.escalated(lead, 'Missing territory or state');
        }

        RoutingResult result = gateway.findBestRep(lead.State, lead.Industry, 0);
        lead.OwnerId = result.repId;
        lead.Status = 'Working';
        update lead;
        return AssignmentResult.assigned(lead, result.repId, result.repName);
    }

    public class LeadAssignmentException extends Exception {}
}

