public class TaxStrategyFactory implements ITaxStrategyFactory {
    public ITaxStrategy getStrategy(String countryCode) {
        if (countryCode == 'US') {
            return new USTaxStrategy();
        } else if (countryCode == 'FR') {
            return new FRTaxStrategy();
        }
        return null;
    }
}