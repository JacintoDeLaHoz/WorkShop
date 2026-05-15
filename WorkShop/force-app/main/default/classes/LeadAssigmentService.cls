/**
 */

public with sharing class LeadAssigmentService {

    public void assignLead(Lead lead){
        Group group = [
                SELECT Id
                FROM Group
                WHERE Name = 'Unassigned_Lead'
                AND Type = 'Queue'
                LIMIT 1
        ];

        if (String.isBlank(lead.State) || String.isBlank(lead.Industry)){
            lead.OwnerId = group.Id;
            lead.Status = 'Open';
            update lead;
            return;
        }
    }
}