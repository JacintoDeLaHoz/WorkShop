
public with sharing class RoutingResult {
    public boolean repFound;
    public Id repId;
    public String repName;
    public String errorMessage;

    public static RoutingResult assigned(Id repId, String repName){
        RoutingResult result = new RoutingResult();
        result.repFound = true;
        result.repId = repId;
        result.repName = repName;
        return result;
    }

    public static RoutingResult noRepAvailable(){
        RoutingResult result = new RoutingResult();
        result.repFound = false;
        result.errorMessage = 'No Rep Available for this territory/state';
        return result;
    }

    public static RoutingResult gatewayError(String message){
        RoutingResult result = new RoutingResult();
        result.repFound = false;
        result.errorMessage = message;
        return result;
    }
}