//
//  TestBedUITest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//
#import "TestBedUITest.h"

@implementation TestBedUITest

- (void)setUp {
    self.continueAfterFailure = NO;
    self.appLaunched = FALSE;
}

- (void)tearDown {
    
}

-(BOOL) trackingDisabled {
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
    }
    XCUIElement *stateElement = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"].checkBoxes[@"Tracking Disabled"];
    return stateElement.value ? TRUE : FALSE;
}

-(void) enableTracking {
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
        sleep(1);
    }
    XCUIElement *stateElement = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"].checkBoxes[@"Tracking Disabled"];
    if (stateElement.value == 0){
        [stateElement click];
    }
}

-(void) disableTracking {
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
        sleep(1);
    }
    XCUIElement *stateElement = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"].checkBoxes[@"Tracking Disabled"];
    if ((int)stateElement.value == 1){
        [stateElement click];
    }
}


- (XCTWaiterResult) launchAppAndWaitForSessionStart {
    
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
    }
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *stateElement = [self trackingDisabled ] ? testbedMacWindow.staticTexts[@"BranchDidStartSessionNotification"] : testbedMacWindow.staticTexts[@"< State >"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:stateElement];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:6];
    XCUIElement *stateElementNext = testbedMacWindow.staticTexts[@"BranchDidOpenURLWithSessionNotification"];
    expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:stateElementNext];
    result = [XCTWaiter waitForExpectations:@[expectation] timeout:6];
    
    return  result;
}

- (void) terminateApp {
    [[[XCUIApplication alloc] init] terminate];
}

- (NSString *) serverRequestString {
    
    XCUIElement *textViewServerRequest = [[[[[XCUIApplication alloc] init].windows[@"TestBed-Mac"] childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeTextView].element;
    return textViewServerRequest.value;
}

- (NSString *) serverResponseString {
    
    XCUIElement *textViewServerRequest = [[[[[XCUIApplication alloc] init].windows[@"TestBed-Mac"] childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:2] childrenMatchingType:XCUIElementTypeTextView].element;
    return textViewServerRequest.value;
}

- (NSString *) dataTextViewString {
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] initWithBundleIdentifier:@"io.branch.sdk.TestBed-Mac"].windows[@"TestBed-Mac"];
    XCUIElement *dataTextView = [[[[[XCUIApplication alloc] initWithBundleIdentifier:@"io.branch.sdk.TestBed-Mac"].windows[@"TestBed-Mac"] childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextView].element;
    return dataTextView.value;
}

- (void) setIdentity {
    [[[XCUIApplication alloc] init].windows[@"TestBed-Mac"].collectionViews.staticTexts[@"Set Identity"] click];
}

- (void) logOut {
    [[[XCUIApplication alloc] init].windows[@"TestBed-Mac"].collectionViews.staticTexts[@"Log User Out"] click];
}

- (NSString *) createShortLink {
    
     XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
     [[testbedMacWindow.scrollViews.collectionViews.groups matchingIdentifier:@"APPActionItemView"].staticTexts[@"Create Short Link"] click];
     XCUIElement *textView = [[[[testbedMacWindow childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextView] element];
     return textView.value;
}

- (void) openLastLink {
    
}

- (NSString *) getErrorString {
    NSString *errorString = [[[[[XCUIApplication alloc] init].windows[@"TestBed-Mac"] childrenMatchingType:XCUIElementTypeStaticText] elementBoundByIndex:4] value];
    return errorString;
}

- (void) logEvent:(NSString *)eventName {
    
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *sendV2EventStaticText = testbedMacWindow.collectionViews.staticTexts[@"Send Event"];
    XCUIElementQuery *sheetsQuery = testbedMacWindow.sheets;
    XCUIElement *button = [sheetsQuery.comboBoxes[@"Select V2 Event"] childrenMatchingType:XCUIElementTypeButton].element;
    XCUIElementQuery *elementsQuery = sheetsQuery.scrollViews.otherElements;
    XCUIElement *sendButton = sheetsQuery.buttons[@"Send"];
    
    [sendV2EventStaticText click];
    [button click];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"value == '%@'",eventName]];
    [[[elementsQuery childrenMatchingType:XCUIElementTypeTextField] elementMatchingPredicate:predicate] click];
    [sendButton click];
}

- (void) logAllEvents {
    
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *sendV2EventStaticText = testbedMacWindow.collectionViews.staticTexts[@"Send Event"];
    XCUIElementQuery *sheetsQuery = testbedMacWindow.sheets;
    XCUIElement *button = [sheetsQuery.comboBoxes[@"Select V2 Event"] childrenMatchingType:XCUIElementTypeButton].element;
    XCUIElementQuery *elementsQuery = sheetsQuery.scrollViews.otherElements;
    XCUIElement *sendButton = sheetsQuery.buttons[@"Send"];

    int numberOfElementsLeft = 0;
    int counter = 0 ;
    do{
        [sendV2EventStaticText click];
        [button click];
        numberOfElementsLeft = (int)[[[elementsQuery childrenMatchingType:XCUIElementTypeTextField] allElementsBoundByIndex] count];
        [[[elementsQuery childrenMatchingType:XCUIElementTypeTextField] elementBoundByIndex:counter] click];
        counter += 1;
        numberOfElementsLeft = numberOfElementsLeft - counter;
        [sendButton click];
    } while (numberOfElementsLeft > 0);
}

@end
