@IsTest
public class MockTaxFactory implements ITaxStrategyFactory {
    public ITaxStrategy getStrategy(String countryCode) {
        return new MockUSTaxStrategy();
    }
}