//
//  TestBedUITest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//
#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

@implementation TestBedUITest

- (void)setUp {
    
    self.continueAfterFailure = YES;
    self.appLaunched = FALSE;
    self.trackingState = TRACKING_STATE_UNKNOWN ;
}

- (void)tearDown {
    
}

-(NSString *) webPageURLWithRedirection:(BOOL)enabled {
    
    if (!enabled) {
        return [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestWebPage.html"]; //URL of the webpage
    } else {
        return [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestRedirectionWebPage.html"]; //URL of the webpage with redirection enabled.
    }
}

-(void) enableTracking {
    
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
        sleep(3);
    }
    
    if (self.trackingState == TRACKING_ENABLED)
        return;
    
    XCUIElement *element = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"].checkBoxes[@"Tracking Disabled"];
    NSString *eleValue = [NSString stringWithFormat:@"%@" , element.value ];
    if ( [eleValue isEqualToString:@"1"]){
        [element click];
        self.trackingState = TRACKING_ENABLED;
    }
}

-(void) disableTracking {
    
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
        sleep(3);
    }
    
    if (self.trackingState == TRACKING_DISABLED)
        return;
    
    XCUIElement *element = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"].checkBoxes[@"Tracking Disabled"];
    NSString *eleValue = [NSString stringWithFormat:@"%@" , element.value ];
    if ( [eleValue isEqualToString:@"0"]){
        [element click];
        self.trackingState = TRACKING_DISABLED;
    }
}


- (XCTWaiterResult) launchAppAndWaitForSessionStart {
    
    if (!self.appLaunched) {
        [[[XCUIApplication alloc] init] launch];
        self.appLaunched = TRUE;
    }
   
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *stateElement = [self trackingDisabled ] ?  testbedMacWindow.staticTexts[@"< State >"] : testbedMacWindow.staticTexts[@"BranchDidStartSessionNotification"] ;
    
    // Wait for BranchDidStartSessionNotification
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:stateElement];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:3];
    
    //If failed, check for BranchDidOpenURLWithSessionNotification
    if (result != XCTWaiterResultCompleted)
    {
        XCUIElement *stateElementNext = testbedMacWindow.staticTexts[@"BranchDidOpenURLWithSessionNotification"];
        expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:stateElementNext];
        result = [XCTWaiter waitForExpectations:@[expectation] timeout:3];
    }
    
    return  result;
}

-(void) terminateTestBed {
    if (self.appLaunched) {
        [[[XCUIApplication alloc] init] activate];
        [[[XCUIApplication alloc] init] terminate];
    }
    self.appLaunched = FALSE;
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
    
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *stateElementNext = testbedMacWindow.staticTexts[@"BranchDidOpenURLWithSessionNotification"];
    if ([stateElementNext waitForExistenceWithTimeout:15] != NO) {
        XCUIElement *dataTextView = [[[testbedMacWindow childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextView].element;
        return dataTextView.value;
        
    } else {
        XCTFail("BranchDidOpenURLWithSessionNotification not received in 15 seconds");
    }
    
    return @"";
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

- (void) validateDeepLinkDataForRedirectionEnabled:(bool)enabled {
    
    NSMutableString *deepLinkDataString = [[NSMutableString alloc] initWithString:[self dataTextViewString]] ;
    
    XCTAssertTrue([deepLinkDataString isNotEqualTo:@""]);
    
    [deepLinkDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    //Data received from server is not properly formatted. So adding quotes here. Will be removed later on when it will be fixed.
    [deepLinkDataString replaceOccurrencesOfString:@"website" withString:@"\"website\"" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"message :" withString:@"\"message\" :" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"MacSDK," withString:@"\"message\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"QuickLink," withString:@"\"message\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"marketing," withString:@"\"marketing\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    NSError *error;
    NSDictionary *deepLinkDataDictionary = [NSJSONSerialization JSONObjectWithData: [ deepLinkDataString dataUsingEncoding:NSUTF8StringEncoding ] options:0 error:&error];
    XCTAssertEqualObjects(deepLinkDataDictionary[@"+match_guaranteed"], @1 );
    if (enabled) {
        XCTAssertEqualObjects(deepLinkDataDictionary[@"~referring_link"], @TESTBED_CLICK_LINK_WITH_REDIRECTION);
    }
    else {
        XCTAssertEqualObjects(deepLinkDataDictionary[@"~referring_link"], @TESTBED_CLICK_LINK);
    }
}

@end
