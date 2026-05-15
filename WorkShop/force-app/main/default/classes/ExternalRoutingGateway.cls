public with sharing class ExternalRoutingGateway implements IRoutingGateway {
    public RoutingResult findBestRep(
            String territory,
            String industry,
            Integer currentLoad
    ) {
        return RoutingResult.noRepAvailable();
    }
}