({
    getSettlementRecord : function(component, settlementId) {
        debugger;
        console.log('settlementId:' + settlementId);
        var action = component.get("c.getSettlement");
        action.setParams({ settlementId : settlementId }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.settlement", result);
                this.updateBalanceDue(component);
            } else {
                console.log('error' +state);
            }
        });
        $A.enqueueAction(action);
    },
    updateBalanceDue : function(component){
        debugger;
        var subTotal = 0;
        var balanceToClient = 0;
        var expenseComp = component.find('expensetable');
        subTotal += expenseComp.get("v.subtotal");
    
        var damageComp = component.find('damagetable');
        subTotal += damageComp.get("v.subtotal");
    
        var settle = component.get("v.settlement");
        if (settle != null){
            balanceToClient =  settle.Amount__c + settle.MedPay_Available__c - settle.Attorney_Fee__c - subTotal;
            component.set("v.totalDueAmount", subTotal.toFixed(2)); 
            component.set("v.totalToClient",  balanceToClient.toFixed(2));
        }
        
	},
    retrievePageLayout : function(component, helper) {
        //debugger;
		var action = component.get("c.getPageLayoutMetadata");
        var pageLayoutName = component.get("v.pageLayoutName");
        
        console.log("pageLayoutName: " + pageLayoutName);
        
        var actionParams = {
            "pageLayoutName" : pageLayoutName
        };
        
        action.setParams(actionParams);
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log("callback state: " + state);
            
            if (component.isValid() && state === "SUCCESS") {
                var pageLayout = response.getReturnValue();
                console.log("pageLayout: " + pageLayout.toString());
                
                component.set("v.pageLayout", pageLayout);
            }
        });
        
        $A.enqueueAction(action);
    }
})