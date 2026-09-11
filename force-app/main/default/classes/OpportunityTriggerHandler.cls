/**
 * @description Handler del OpportunityTrigger: delega la lógica en
 *              OpportunityPriorityService. Se mantiene deliberadamente delgado;
 *              toda la lógica vive en el servicio para que sea testeable de
 *              forma aislada.
 */
public with sharing class OpportunityTriggerHandler {

    /**
     * @description Punto de entrada after insert.
     * @param newList Trigger.new
     */
    public static void afterInsert(List<Opportunity> newList) {
        OpportunityPriorityService.process(newList, null);
    }

    /**
     * @description Punto de entrada after update.
     * @param newList Trigger.new
     * @param oldMap  Trigger.oldMap
     */
    public static void afterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        OpportunityPriorityService.process(newList, oldMap);
    }
}
