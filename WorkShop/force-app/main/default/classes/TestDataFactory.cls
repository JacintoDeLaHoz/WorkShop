
@IsTest
public class TestDataFactory {
    public static LeadBuilder aLead() { return new LeadBuilder(); }
    public static QueueBuilder aQueue() { return new QueueBuilder(); }

    public class LeadBuilder {
        private String lastName = 'Test';
        private String company = 'Acme Corp';
        private String territory;
        private String industry;
        private Id ownerId;

        public LeadBuilder fromTerritory(String s)  { territory = s; return this; }
        public LeadBuilder inIndustry(String i)     { industry = i; return this; }
        public LeadBuilder withNoTerritory()        { territory = null; return this; }
        public LeadBuilder withNoIndustry()         { industry = null; return this; }
        public LeadBuilder alreadyAssignedTo(Id id) { ownerId = id; return this; }

        public Lead save() {
            Lead l = new Lead(
                    LastName = lastName, Company = company,
                    State = territory, Industry = industry
            );
            if (ownerId != null) l.OwnerId = ownerId;
            insert l;
            return l;
        }
    }

    public class QueueBuilder {
        private String name = 'Unassigned_Leads';
        public QueueBuilder named(String n) { name = n; return this; }

        public Group save() {
            Group q = new Group(Name = name, Type = 'Queue');
            insert q;
            insert new QueueSobject(QueueId = q.Id, SobjectType = 'Lead');
            return q;
        }
    }
}