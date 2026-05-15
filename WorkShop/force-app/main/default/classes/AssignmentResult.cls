public class AssignmentResult {
    public Lead updatedLead { get; private set;}
    public Boolean wasAssigned { get; private set;}
    public Boolean wasEscalated { get; private set;}
    public Boolean wasSkipped { get; private set;}
    public Id assignedRepId { get; private set;}
    public String assignedRepName { get; private set;}
    public String escalationReason { get; private set;}

    public static AssignmentResult assigned(Lead lead, Id id, String name){
        AssignmentResult result = new AssignmentResult();
        result.updatedLead = lead;
        result.wasAssigned = true;
        result.wasEscalated = false;
        result.wasSkipped = false;
        result.assignedRepId = id;
        result.assignedRepName = name;
        return result;
    }

    public static AssignmentResult escalated(Lead lead, String reason){
        AssignmentResult result = new AssignmentResult();
        result.updatedLead = lead;
        result.wasAssigned = false;
        result.wasEscalated = true;
        result.wasSkipped = false;
        result.escalationReason = reason;
        return result;
    }

    public static AssignmentResult alreadyAssigned(Lead lead){
        AssignmentResult result = new AssignmentResult();
        result.updatedLead = lead;
        result.wasAssigned = false;
        result.wasEscalated = false;
        result.wasSkipped = true;
        return result;
    }
}
