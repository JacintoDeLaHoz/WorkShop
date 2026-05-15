
public interface IRoutingGateway {
    RoutingResult findBestRep(String territory, String industry, Integer currentLoad);
}