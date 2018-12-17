declare module "@salesforce/apex/SettlementCalculatorController.getFieldLineMembers" {
  export default function getFieldLineMembers(param: {forceReadOnly: any, sourceObjectAPIName: any, paymentObjectAPIName: any, isEligiblePayment: any}): Promise<any>;
}
declare module "@salesforce/apex/SettlementCalculatorController.getSettlement" {
  export default function getSettlement(param: {settlementId: any}): Promise<any>;
}
declare module "@salesforce/apex/SettlementCalculatorController.getPreviousPaymentLines" {
  export default function getPreviousPaymentLines(param: {settlementId: any, sourceObjectAPIName: any, paymentObjectAPIName: any}): Promise<any>;
}
declare module "@salesforce/apex/SettlementCalculatorController.getPaymentLines" {
  export default function getPaymentLines(param: {settlementId: any, sourceObjectAPIName: any, paymentObjectAPIName: any}): Promise<any>;
}
declare module "@salesforce/apex/SettlementCalculatorController.savePaymentLines" {
  export default function savePaymentLines(param: {linesToSave: any, labelType: any}): Promise<any>;
}
declare module "@salesforce/apex/SettlementCalculatorController.getPageLayoutMetadata" {
  export default function getPageLayoutMetadata(param: {pageLayoutName: any}): Promise<any>;
}
