({
	doInit : function(component, event, helper){
		//debugger;
		console.log('initializing SettlementDataTable: ' + component.get("v.label"));
		console.log('initializing SettlementDataTable resetSelectedRows:' + component.get("v.resetSelectedRows"));
		helper.getFieldMembers(component);
		helper.getPreviousPaymentLines(component);
		helper.getPaymentLines(component);
		var resetSelectedRows = component.get("v.resetSelectedRows");
		if ( resetSelectedRows ){
			var selectedRows = [];
			component.set("v.selectedRows", selectedRows);
		}
		helper.calculateTotals(component);
	},
	handleRowAction : function(component, event, helper) {
		debugger;
		var label = component.get("v.label");
		var selectedRows = event.getParam('selectedRows');
		var subTotal = 0;
		var total = 0;
		component.set("v.draftValues", selectedRows);

		helper.calculateTotals(component);
		
		// var appEvent = $A.get("e.c:SettlementDataChange");
		// appEvent.fire();
	},
	handleCellChange : function(component, event, helper){
		debugger;
		var compDraftValues = component.get("v.draftValues");
		var draftValues = event.getParam('draftValues');
		var recordRows = component.get("v.payments");
		var keyField = component.get("v.keyField");

		var draftRowsMap = new Map();
		if (keyField == "Expense__c"){
			for (var i = 0; i < compDraftValues.length; i++){
				draftRowsMap.set(compDraftValues[i].Expense__c, compDraftValues[i]);
			}
		}

		for (var i = 0; i < draftValues.length; i++){
			for(var l =0; l< recordRows.length; l++){
				if (keyField == "Expense__c"){
					if (draftValues[i].Expense__c == recordRows[l].Expense__c){
						if (draftValues[i].Amount__c > 0){
							recordRows[l].Amount__c = parseFloat(draftValues[i].Amount__c);		
						}
						
						if (draftValues[i].Payment_Date__c != null){
							recordRows[l].Payment_Date__c = draftValues[i].Payment_Date__c;	
						}
						
						if (draftValues[i].Payment_Comment__c != null){
							recordRows[l].Payment_Comment__c = draftValues[i].Payment_Comment__c;
						}
						draftRowsMap.set(recordRows[l].Expense__c, recordRows[l]);
					}
				} else {
					if (draftValues[i].Damage__c == recordRows[l].Damage__c){
						recordRows[l].Amount__c = parseFloat(draftValues[i].Amount__c);
						draftRowsMap.set(recordRows[l].Damage__c, recordRows[l]);
					}
				}
			}
		}
		

		draftValues = [];
		for (var ele of draftRowsMap.values()){
			draftValues.push(ele);
		}
		
		component.set("v.draftValues", draftValues);

		helper.calculateTotals(component);
		
		// var appEvent = $A.get("e.c:SettlementDataChange");
		// appEvent.fire();

	},
	handleSave : function(component, event, helper){
		debugger;
		var label = component.get("v.label")
		var action = component.get("c.savePaymentLines");
		var draftValues = component.get("v.draftValues")
		var jsonLines = JSON.stringify(draftValues);
        //console.log('linesToSave: ' + jsonLines);
		action.setParams({ "linesToSave" : jsonLines, "labelType" : label}); 
		
        console.log(action.params);
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue();

				helper.getPreviousPaymentLines(component);
				helper.getPaymentLines(component);
				draftValues = [];
				component.set("v.draftValues", draftValues);

				$A.get('e.force:refreshView').fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The Settlement Records saved.",
                    "type": "success"
                });
                toastEvent.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "The Expense Records failed to save.",
                    "type": "error"
                });
                toastEvent.fire();
                console.log('error');
            }
        });
        
        $A.enqueueAction(action);
	}
})