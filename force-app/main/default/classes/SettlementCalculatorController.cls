/*
Copyright (c) 2018 Trifecta Technologies Inc.
All rights reserved.

Trifecta (We/Us) grant (You/Your) non-exclusive, 
non-transferable, non-redistributable, royalty-free license to use and run (as applicable) 
solely for Your internal business purposes associated with Your use of Our code developed by Us for You.  
We retain all rights, title and interest in its respective intellectual property and We retain all ownership 
rights in this code.
*/

public with sharing class SettlementCalculatorController {

    /**
     * Retrieve the Field Definitions for the DataTable component
     */
    @AuraEnabled
    public static String getFieldLineMembers(Boolean forceReadOnly, String sourceObjectAPIName, String paymentObjectAPIName, Boolean isEligiblePayment){
        system.debug('getFieldLineMembers:' + forceReadOnly);
        system.debug('sourceObjectAPIName: ' + sourceObjectAPIName);
        
        //String sObjectAPIName = 'litify_pm__Expense__c';
        Map<String, Schema.SObjectField> fieldMap = getSObjectFieldMap(paymentObjectAPIName);

        //Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Expense_Payment_Reduction__c.fields.getMap();

        return getPaymentLineFields(sourceObjectAPIName, fieldMap, forceReadOnly, isEligiblePayment);
    }

    private static Map<String, Schema.SObjectField> getSObjectFieldMap(String sObjectAPIName){
        Map<String, Schema.SObjectField> fieldMap;
        Schema.DescribeSobjectResult result = getSobjectDescribe(sObjectAPIName);
        fieldMap = result.fields.getMap();
        system.debug('getSObjectFieldMap fieldMap: ' + fieldMap);
        return fieldMap;
    }

    private static Schema.DescribeSobjectResult getSobjectDescribe(String sObjectAPIName){
        String[] types = new String[]{sObjectAPIName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSobjectResult res = results[0];
        return res;
    }

    private static String getPaymentLineFields(String sObjectAPIName, Map<String, Schema.SObjectField> fieldMap, Boolean forceReadOnly, Boolean isEligiblePayment){
        System.debug('getPaymentLineFields sObjectAPIName:' + sObjectAPIName);
        System.debug('getPaymentLineFields fieldMap: ' + fieldMap);
        System.debug('getPaymentLineFields forceReadOnly: ' +forceReadOnly);
        List<Settlement_Calculator_Field__mdt> fields;
        Settlement_Object__mdt settlementObjType = getSettlementMDType(sObjectAPIName);

        if (isEligiblePayment){
            fields = [SELECT Display_Order__c, IsReadOnly__c, MasterLabel, Field_API_Name__c FROM Settlement_Calculator_Field__mdt WHERE Settlement_Object__c = :settlementObjType.Id AND Display_In_Eligible_Payment__c = true ORDER BY Display_Order__c];
        }
        else{
            fields = [SELECT Display_Order__c, IsReadOnly__c, MasterLabel, Field_API_Name__c FROM Settlement_Calculator_Field__mdt WHERE Settlement_Object__c = :settlementObjType.Id AND Display_In_Previous_Payment__c = true ORDER BY Display_Order__c];
        }
        String result = '';
        
        for (Settlement_Calculator_Field__mdt f : fields){
            Schema.SObjectField sof = fieldMap.get(f.Field_API_Name__c);
            Schema.DescribeFieldResult dr = sof.getDescribe();

            if (result != ''){
                result += ',';
            }
            String jsonPart = '{';
            jsonPart += '"label":"' + dr.getLabel() + '",';
            jsonPart += '"type":"' + getAuraTypes().get((dr.getType() + '')) + '",';
            jsonPart += '"fieldName":"' + dr.getName() + '",';
            jsonPart += '"cellAttributes": { "alignment": "left" }';
            if (!forceReadOnly){
                jsonPart += ', "editable":' + !f.IsReadOnly__c;
            }
            jsonPart += '}';
            result += jsonPart;
        }
        System.debug('getPaymentLineFields result:' + result);
        return '['+result+']';
    }

    /**
     * Query the  Settlement__c Record for all the field values
     * @param settlementId Id of the Settlemnt
     */
    @AuraEnabled
    public static Settlement__c getSettlement(String settlementId){
        System.debug('settlmentId:' + settlementId);

        String soqlQuery = 'SELECT RecordType.DeveloperName, ' + getSObjectFields('Settlement__c') + ' FROM Settlement__c WHERE Id = \'' + settlementId + '\' LIMIT 1';
        System.debug('settlment soql query: ' + soqlQuery);
        Settlement__c settlement = Database.query(soqlQuery);
        system.debug('Settlement: ' + settlement);
        return settlement;
    }

    /**
     * Retrieve all the Settlemtn Records eligible to be added to this Settlement or that have already been added to the Settlement
     * @param settlementId Id of the Settlemnt
     */
    @AuraEnabled
    public static List<sObject> getPreviousPaymentLines(String settlementId, String sourceObjectAPIName, String paymentObjectAPIName){
        System.debug('getPreviousPaymentLines settlementId:' + settlementId);
        System.debug('getPreviousPaymentLines sourceObjectAPIName:' + sourceObjectAPIName);
        List<sObject> currentItems = new List<sObject>();
        String queryString;
        
        if (!String.isBlank(settlementId)){
            
            String soqlLitifyWhere = ' WHERE Settlement__c ='; 
            queryString = 'SELECT ' + getSObjectFields(paymentObjectAPIName) + ' FROM ' + paymentObjectAPIName;
            queryString += soqlLitifyWhere + '\'' + settlementId + '\'';
            System.debug('queryString:' + queryString);
            currentItems = Database.query(queryString);    
        }
        system.debug('getPreviousPaymentLines currentItems' + currentItems);
        return currentItems;
    }

    private static Schema.sObjectType getSobjectType(String sObjectAPIName){
        Schema.DescribeSobjectResult result=  getSobjectDescribe(sObjectAPIName);
        Schema.sObjectType objType = result.getSobjectType();
        return objType;
    }

    /**
     * Retrieve all the Settlemtn Records eligible to be added to this Settlement or that have already been added to the Settlement
     * @param settlementId Id of the Settlemnt
     */
    @AuraEnabled
    public static List<sObject> getPaymentLines(String settlementId, String sourceObjectAPIName, String paymentObjectAPIName){
        System.debug('getPreviousPaymentLines settlementId:' + settlementId);
        System.debug('getPreviousPaymentLines sourceObjectAPIName:' + sourceObjectAPIName);
       
        // List<Settlement__c> settlements = new List<Settlement__c>();
        List<sObject> expenseLines = new List<sObject>();
        List<sObject> items = new List<sObject>();
        String queryString;
        
       //get the Matter Id so we can retrieve all the settlements for this matter and be sure 
       //we do not add Items to a settlement that have been added to another settlment
        if (!String.isBlank(settlementId)){
            Settlement__c existingSettlement = [SELECT Matter__c FROM Settlement__c WHERE id =: settlementId LIMIT 1];
            String matterId = existingSettlement.Matter__c;            
            String soqlLitifyWhere = ' WHERE litify_pm__Matter__c =';
            queryString = 'SELECT ' + getSObjectFields(sourceObjectAPIName) + ' FROM ' + sourceObjectAPIName ;
            queryString += soqlLitifyWhere + '\'' + matterId + '\' AND Balance_Due__c > 0.00';
            System.debug('queryString:' + queryString);

            List<sObject> currentItems = Database.query(queryString);
            Schema.sObjectType sobjType = getSobjectType(paymentObjectAPIName);

            items = copyFields(currentItems, sourceObjectAPIName, settlementId, sobjType);
            
        }
        system.debug('getExpenseLines items' + items);
        return items;
    }

    @AuraEnabled
    public static List<sObject> savePaymentLines(String linesToSave, String labelType){
        system.debug('savePaymentLines: ' + linesToSave);
        List <sObject> lines;
        if (labelType == 'Expenses'){
            lines = (List<Expense_Payment_Reduction__c>) JSON.deserializeStrict(linesToSave, List<Expense_Payment_Reduction__c>.class);
        }
        else {
            lines = (List<Damage_Payment_Reduction__c>) JSON.deserializeStrict(linesToSave, List<Damage_Payment_Reduction__c>.class);
        }
        
        insert lines;
        return null;
    }

    private static Map<String,String> auraTypes {get; set;}

    private static Map<String,String> getAuraTypes() {
        if(auraTypes!=null) {
            return auraTypes;
        }
        else {
            auraTypes = new Map<String,String>();
            auraTypes.put('BOOLEAN','checkbox');
            auraTypes.put('DATE','date');
            auraTypes.put('DATETIME','date');
            auraTypes.put('EMAIL','email');
            auraTypes.put('NUMBER','number');
            auraTypes.put('PHONE','phone');
            auraTypes.put('STRING','text');
            auraTypes.put('CURRENCY','currency');            
        }
        return auraTypes;
    }

    private static String getSObjectFields(String sObjectAPIName){
        List<String> fieldApiNames = new List<String>();
        String[] types = new String[]{sObjectAPIName};
        Schema.DescribeSobjectResult[] dsResults = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fields =  dsResults[0].fields.getMap();

        for (String fieldKey : fields.keySet()){
            Schema.SObjectField currentField = fields.get(fieldKey);
            Schema.DescribeFieldResult curFieldDescribe = currentField.getDescribe();
            if (curFieldDescribe.isAccessible()){
                fieldApiNames.add(curFieldDescribe.getName());    
            }
        }
        
        return convertListToString(fieldApiNames);

    }

    private static String convertListToString(List<String> listToConvert){
        String convertedString = '';
        convertedString = String.join(listToConvert, ', ');
        return convertedString;
    }

    /**
     * Copies the field values as specified by fieldPaths from fromSob to toSob
     * @param fromSob The SObject record whose field values are to be copied
     * @param fieldMap Map of From Fiel To Field Mapping. The keyset contains the To Field
     * @param settlementType the set of fields to be copied from fromSob to toSob
     * @param settlementId Id of the Settlemnt
     */
    private static List<sObject> copyFields(List<SObject> fromSobs, Map<String, String> fieldMap, String settlementId, Schema.sObjectType sobjType) {  
        System.debug('copyFields: ' + fromSobs);
        System.debug('fieldMap:' + fieldMap);
        List<SObject> items = new List<SObject>();
        for (sObject fromSob : fromSobs){
            SObject item = sobjType.newSobject();
            for (String fieldPath: fieldMap.keySet()) {
                Object srcValue = fromSob.get(fieldMap.get(fieldPath));
                item.put(fieldPath, srcValue);           
            }
            item.put('Type__c', 'Settlement Payment');
            item.put('Settlement__c', settlementId);
            item.put('Payment_Date__c', Date.today());
            items.add(item);    
        }
        
        System.debug('copyFields return: items: ' + items);
        return items;
    }

    
    /**
     * Retrieves the field paths from the fields within fieldset and passes to copyFields(SObject fromSob, SObject toSob, Set<String> fieldPaths)
     * @param fromSob The SObject record whose field values are to be copied
     * @param settlementType the matadata containing the object type to be copied
     * @param settlementId Id of the Settlemnt
     */
    private static List<sObject> copyFields(List<SObject> fromSobs, String sObjectAPIName, String settlementId, Schema.sObjectType sobjType) {
        Map<String, String> fieldMap = new Map<String, String>();
        Settlement_Object__mdt objType = getSettlementMDType(sObjectAPIName);
        List<Settlement_Line_Field_Mapping__mdt> items = [SELECT 
                                                            DeveloperName,
                                                            Id,
                                                            Label,
                                                            Language,
                                                            MasterLabel,
                                                            NamespacePrefix,
                                                            QualifiedApiName,
                                                            Settlement_Line_Field_API_Name__c,
                                                            Settlement_Object__c,
                                                            Source_Field_API_Name__c 
                                                            FROM Settlement_Line_Field_Mapping__mdt
                                                            WHERE Settlement_Object__c = : objType.Id];
        
        for (Settlement_Line_Field_Mapping__mdt item : items){
            fieldMap.put(item.Settlement_Line_Field_API_Name__c, item.Source_Field_API_Name__c);
        }
        

        return copyFields(fromSobs, fieldMap, settlementId, sobjType);
    }

    private static Settlement_Object__mdt getSettlementMDType(String sObjectAPIName){
        Settlement_Object__mdt objType = [SELECT sObject_API_Name__c, Id FROM Settlement_Object__mdt WHERE sObject_API_Name__c =:sObjectAPIName LIMIT 1];
        return objType;
    } 

    @AuraEnabled
    public static PageLayout getPageLayoutMetadata(String pageLayoutName) {
        system.debug('  pageLayoutName: ' + pageLayoutName);
        
        List<String> componentNameList = new List<String>{pageLayoutName};
        
        if (String.isBlank(pageLayoutName)) {
            return new PageLayout();
        }
        
        List<Metadata.Metadata> layouts =  
            Metadata.Operations.retrieve(Metadata.MetadataType.Layout, componentNameList);

        system.debug('  layouts: ' + layouts);

        if (layouts.size() == 1) {
            system.debug('  layouts[0]: ' + layouts[0]);
            
            return new PageLayout((Metadata.Layout) layouts[0]);
        }
        
        return new PageLayout();
    }

    public class PageLayout {
        @AuraEnabled
        public List<PageLayoutSection> Sections { get; set; }
        
        public PageLayout() {
            Sections = new List<PageLayoutSection>();
        }
        
        public PageLayout(Metadata.Layout layout) {
            this();

            for (Metadata.LayoutSection section : layout.layoutSections) {
                if (section.style != Metadata.LayoutSectionStyle.CustomLinks) {
                    Sections.add(new PageLayoutSection(section));
                }
            }
        }
    }
    
    public class PageLayoutSection {
        @AuraEnabled
        public List<PageLayoutSectionColumn> Columns { get; set; }
        
        @AuraEnabled
        public String Label { get; set; }
        
        public PageLayoutSection(Metadata.LayoutSection section) {
            Columns = new List<PageLayoutSectionColumn>();
            
            Label = section.label;
            
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                Columns.add(new PageLayoutSectionColumn(column));
            }
        }
    }
    
    public class PageLayoutSectionColumn {
        @AuraEnabled
        public List<PageLayoutField> Fields { get; set; }
        
        public PageLayoutSectionColumn(Metadata.LayoutColumn column) {
            Fields = new List<PageLayoutField>();
            
            if (column.layoutItems == null) {
                return;
            }

            for (Metadata.LayoutItem item : column.layoutItems) {
                Fields.add(new PageLayoutField(item));
            }
        }
    }
    
    public class PageLayoutField {
        @AuraEnabled
        public String APIName { get; set; }
        
        public PageLayoutField(Metadata.LayoutItem item) {
            APIName = item.field;
        }
    }

}