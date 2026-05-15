@IsTest
public class LeadAssignmentMocks {

    public class RoutingAlwaysSucceeds implements IRoutingGateway {
        private Id repId; private String repName;
        public RoutingAlwaysSucceeds(Id id, String name) {
            this.repId = id; this.repName = name;
        }
        public RoutingResult findBestRep(String t, String i, Integer l) {
            return RoutingResult.assigned(repId, repName);
        }
    }
}