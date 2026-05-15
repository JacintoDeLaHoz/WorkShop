public with sharing class LeadAssigmentService {

    private final IRoutingGateway gateway;

    public LeadAssigmentService(){
        this.gateway =new ExternalRoutingGateway();
    }

    @TestVisible
    private LeadAssigmentService(IRoutingGateway gateway);

    public void assignLead(Lead lead){
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

        RoutingResult result = gateway.findBestRep(lead.state, lead.Industry, 0);
        lead.OwnerId = result.repId;
        lead.Status = 'Working';
        update lead;
        return AssignmentResult.assigned(lead, result.repId, result.repName);
    }

    public class AssignmentResult{
        public lead updateLead { get; private set;}
        public Boolean wasAssigned { get; private set;}
        public Boolean wasEscalated { get; private set;}
        public Boolean wasSkipped { get; private set;}
        public Id assignedRepId { get; private set;}
        public String assignedRepName { get; private set;}
        public String escalationReason { get; private set;}

        public static AssignmentResult assigned(Lead lead, Id id, String name){
            AssignmentResult result = new AssignmentResult();
            result.updateLead = lead;
            result.wasAssigned = true;
            result.wasEscalated = false;
            result.wasSkipped = false;
            result.assignedRepId = id;
            result.assignedRepName = name;
            return result;
        }

        public static AssignmentResult escalated(Lead lead, String reason){
            AssignmentResult result = new AssignmentResult();
            result.updateLead = lead;
            result.wasAssigned = false;
            result.wasEscalated = true;
            result.wasSkipped = false;
            result.escalationReason = reason;
            return result;
        }

        public static AssignmentResult alreadyAssigned(Lead lead){
            AssignmentResult result = new AssignmentResult();
            result.updateLead = lead;
            result.wasAssigned = false;
            result.wasEscalated = false;
            result.wasSkipped = true;
            return result;
        }
    }

    public class LeadAssignmentException extends Exception {}
}