({
	getFieldMembers : function(component){
        debugger;
        this.getReadOnlyFieldMembers(component);
        this.getEditableFieldMembers(component);
    },
    getReadOnlyFieldMembers : function(component){
        //debugger;
		var action = component.get("c.getFieldLineMembers");
		var sourceType = component.get("v.sourceType");
		var paymentType = component.get("v.paymentType");
		action.setParams({ "forceReadOnly" : true, "sourceObjectAPIName" : sourceType, "paymentObjectAPIName" : paymentType, isEligiblePayment : false}); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = JSON.parse(response.getReturnValue());
                console.log('JSON result: ' + response.getReturnValue());
                var fields = [];
                for (var i=0 ;i < result.length ;i++ ){
                   fields.push(result[i]);
                }
                component.set('v.readOnlyColumns', fields);
            } else {
                console.log('error' +state);
            }
        });
        $A.enqueueAction(action);
	},
	getEditableFieldMembers : function(component){
        //debugger;
		var action = component.get("c.getFieldLineMembers");
		var sourceType = component.get("v.sourceType");
		var paymentType = component.get("v.paymentType");
		action.setParams({ "forceReadOnly" : false, "sourceObjectAPIName" : sourceType, "paymentObjectAPIName" : paymentType, isEligiblePayment : true}); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = JSON.parse(response.getReturnValue());
                console.log('JSON result: ' + response.getReturnValue());
                var fields = [];
                for (var i=0 ;i < result.length ;i++ ){
                   fields.push(result[i]);
                }
                component.set('v.columns', fields);
            } else {
                console.log('error' +state);
            }
        });
        $A.enqueueAction(action);
	},
	getPreviousPaymentLines: function(component){
		//debugger;
		var settlementId = component.get("v.settlementId");
		var sourceType = component.get("v.sourceType");
		var paymentType = component.get("v.paymentType");
        var action = component.get("c.getPreviousPaymentLines");
        action.setParams({ settlementId : settlementId, "sourceObjectAPIName" : sourceType, "paymentObjectAPIName" : paymentType }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.previousPayments", result);
				console.log('expenses data result ' + result);
				this.calculateTotals(component);
                
            } else {
                console.log('error' +state);
            }
        });
        $A.enqueueAction(action);
	},
	getPaymentLines : function(component){
		//debugger;
		var settlementId = component.get("v.settlementId");
		var sourceType = component.get("v.sourceType");
		var paymentType = component.get("v.paymentType");
        var action = component.get("c.getPaymentLines");
        action.setParams({ settlementId : settlementId, "sourceObjectAPIName" : sourceType, "paymentObjectAPIName" : paymentType }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.payments", result);
				console.log('expenses data result ' + result);
				this.calculateTotals(component);
            } else {
                console.log('error' +state);
            }
        });
        $A.enqueueAction(action);
	},
	calculateTotals : function(component){
        debugger;
        var subTotal = 0;
		var draftValues = component.get("v.draftValues")
		if (draftValues != null){
			for (var i=0; i< draftValues.length; i++){
				subTotal += draftValues[i].Amount__c;
			}
		}
        
		var prevPayments = component.get("v.previousPayments")
		if (prevPayments != null){
			for (var i=0; i< prevPayments.length; i++){
				subTotal += prevPayments[i].Amount__c;
			}
		}
        
		component.set("v.subtotal", subTotal);
		var appEvent = $A.get("e.c:SettlementDataChange");
		appEvent.fire();
    }
})