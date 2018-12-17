({
    doInit : function(component, event, helper) {
        debugger;
        var settlementId  = component.get("v.recordId");
        helper.retrievePageLayout(component, helper);
        helper.getSettlementRecord(component, settlementId); 
    },
    handleDataChanged : function(component, event, helper){
        debugger;
        console.log('DataChanged Event Fired');
        helper.updateBalanceDue(component);
    },
    handleRefresh : function(component, event, helper){
        debugger;
        var settlementId  = component.get("v.recordId");
        helper.retrievePageLayout(component, helper);
        helper.getSettlementRecord(component, settlementId);
    }
})