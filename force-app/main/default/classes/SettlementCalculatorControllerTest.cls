/*
Copyright (c) 2018 Trifecta Technologies Inc.
All rights reserved.

Trifecta (We/Us) grant (You/Your) non-exclusive, 
non-transferable, non-redistributable, royalty-free license to use and run (as applicable) 
solely for Your internal business purposes associated with Your use of Our code developed by Us for You.  
We retain all rights, title and interest in its respective intellectual property and We retain all ownership 
rights in this code.
*/

@isTest
private class SettlementCalculatorControllerTest {
    
    @testSetup
    static void dataSetup() {
        Account act = new Account();
        act.Name = 'Test Account 1';
        act.litify_pm__First_Name__c = 'Test';
        act.litify_pm__Last_Name__c = 'Account';
        insert act;

        litify_pm__Matter__c matter = new litify_pm__Matter__c();
        matter.litify_pm__Client__c = act.Id;
        matter.litify_pm__Contingency_Fee_Rate__c = 30;
        insert matter;

        litify_pm__Expense__c expense = new litify_pm__Expense__c();
        expense.litify_pm__Amount__c = 200;
        expense.litify_pm__Matter__c = matter.Id;
        expense.litify_pm__Date__c = Date.today();
        insert expense;

        Settlement__c settlement = new Settlement__c();
        settlement.Matter__c = matter.Id;
        settlement.Amount__c = 5000;
        insert settlement;

        // litify_pm__Damage__c damage = new litify_pm__Damage__c();
        // damage.litify_pm__Amount_Billed__c = 200;
        // damage.litify_pm__Matter__c = matter.Id;
        // damage.litify_pm__Service_Start_Date__c = Date.today();
        // damage.litify_pm__Service_End_Date__c = Date.today();
        // insert damage;
        
    }

    @isTest
    static void testGetFieldLineMembersExpenses() {
        Test.startTest();
        String response = SettlementCalculatorController.getFieldLineMembers(false, 'litify_pm__Expense__c' , 'Expense_Payment_Reduction__c', true);
        Test.stopTest();
        system.assertNotEquals(response, null, 'No Field Line Memebrs were retrieved for Expenses');
    }

    @isTest
    static void testGetFieldLineMembersDamages() {
        Test.startTest();
        String response = SettlementCalculatorController.getFieldLineMembers(false, 'litify_pm__Damage__c' , 'Damage_Payment_Reduction__c', false);
        Test.stopTest();
        system.assertNotEquals(response, null, 'No Field Line Memebrs were retrieved for Damages');
    }

    @isTest
    static void testGetSettlement() {
        Test.startTest();
        Settlement__c settlement = [SELECT Id FROM Settlement__c LIMIT 1];
        
        
        Settlement__c response = SettlementCalculatorController.getSettlement(settlement.Id);
        Test.stopTest();
        system.assertEquals(settlement.Id, response.Id);
    }

    @isTest
    static void testGetPreviousPaymentLines() {
        Test.startTest();
        Settlement__c settlement = [SELECT Id FROM Settlement__c LIMIT 1];  
        List<sObject> response = SettlementCalculatorController.getPreviousPaymentLines(settlement.Id, 'litify_pm__Expense__c' , 'Expense_Payment_Reduction__c');
        Test.stopTest();
        system.assertEquals(response.size(), 0);
    }

    @isTest
    static void testGetSettlementLines() {
        Test.startTest();
        Settlement__c settlement = [SELECT Id FROM Settlement__c LIMIT 1];
        List<sObject> response = SettlementCalculatorController.getPaymentLines(settlement.Id, 'litify_pm__Expense__c' , 'Expense_Payment_Reduction__c');
        Test.stopTest();
        system.assertEquals(response.size(), 1);
    }
    
    @isTest
    static void testSavePaymentLines() {
        Test.startTest();
        Settlement__c settlement = [SELECT Id FROM Settlement__c LIMIT 1];
        
        List<sObject> lines = SettlementCalculatorController.getPaymentLines(settlement.Id, 'litify_pm__Expense__c' , 'Expense_Payment_Reduction__c');
        
        String lineJSON = JSON.serialize(lines);
        
        List<sObject>response = SettlementCalculatorController.savePaymentLines(lineJSON, 'Expenses');

        Test.stopTest();
        system.assertEquals(response, null, 'SaveRecord failed');
    }

    @isTest
    static void getPageLayoutMetadataTest() {
        Test.startTest();
        SettlementCalculatorController.PageLayout layout = SettlementCalculatorController.getPageLayoutMetadata('Account-Account Layout');
        Test.stopTest();
        system.assertNotEquals(null, layout, 'getPageLayoutMetadata method failed');
    }

    @isTest
    static void getPageLayoutMetadataPageLayoutBlankTest() {
        Test.startTest();
        SettlementCalculatorController.PageLayout layout = SettlementCalculatorController.getPageLayoutMetadata('');
        Test.stopTest();
        system.assertNotEquals(null, layout, 'getPageLayoutMetadata method with blank page layout failed');
    }

    @isTest
    static void getPageLayoutMetadataPageLayoutUnknownTest() {
        Test.startTest();
        SettlementCalculatorController.PageLayout layout = SettlementCalculatorController.getPageLayoutMetadata('Nothing');
        Test.stopTest();
        system.assertNotEquals(null, layout, 'getPageLayoutMetadata method with unknown page layout failed');
    }
    
}