({
	handleSectionHeaderClick : function(component, event, helper) {
		debugger;
		event.preventDefault();
		var sectionContainer = component.find('collapsibleSectionContainer');
		$A.util.toggleClass(sectionContainer, "slds-is-open");
	}
})