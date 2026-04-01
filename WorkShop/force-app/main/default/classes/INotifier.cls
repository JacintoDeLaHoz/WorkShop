public interface INotifier {
    void notifyStatusChange(Set<Id> claimIds, String status);
}