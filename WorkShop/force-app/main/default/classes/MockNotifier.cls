@IsTest
public class MockNotifier implements INotifier {
    public Set<Id> notifiedIds = new Set<Id>();

    public void notifyStatusChange(Set<Id> claimIds, String status) {
        notifiedIds.addAll(claimIds);
    }
}