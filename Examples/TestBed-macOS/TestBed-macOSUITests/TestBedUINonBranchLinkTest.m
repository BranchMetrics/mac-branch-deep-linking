//
//  TestBedUINonBranchLinkTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 2/6/21.
//  Copyright © 2021 Branch. All rights reserved.
//


#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

#define SLEEP_TIME_CLICK_BIG        3
#define SLEEP_TIME_CLICK_SMALL      1

@interface TestBedUINonBranchLinkTest : TestBedUITest

@end

@implementation TestBedUINonBranchLinkTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)validateForNonBranchLink {
    
    NSMutableString *deepLinkDataString ;
    
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *stateElementNext = testbedMacWindow.staticTexts[@"BranchDidStartSessionNotification"];
    if ([stateElementNext waitForExistenceWithTimeout:15] != NO) {
        XCUIElement *dataTextView = [[[testbedMacWindow childrenMatchingType:XCUIElementTypeScrollView] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextView].element;
        deepLinkDataString =  dataTextView.value;
        
    } else {
        XCTFail("BranchDidStartSessionNotification not received in 15 seconds");
    }
    
    XCTAssertTrue([deepLinkDataString isNotEqualTo:@""]);
    XCTAssertTrue([deepLinkDataString containsString:@"\"+non_branch_link\" = \"testbed-mac://\""] );
}

- (void)testNonBranchLink {
    
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    if (testBedApp.state != XCUIApplicationStateNotRunning)
            [self terminateTestBed];
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments: @[[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestNonBranchLink.html"]]];
    [safariApp launch];
    sleep(SLEEP_TIME_CLICK_BIG);
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink click];
    sleep(SLEEP_TIME_CLICK_BIG);
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    else {
        NSLog(@"Toggle Element(TestBed Launch Confirmation Dialog) Not Found");
    }
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateForNonBranchLink];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
}

@end
