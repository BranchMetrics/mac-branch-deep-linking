//
//  TestBedUIRaceCondTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/29/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

@interface TestBedUIRaceCondTest : TestBedUITest

@end

@implementation TestBedUIRaceCondTest

- (void)setUp {
   [super setUp];
}

- (void)tearDown {
   [super tearDown];
}

-(void)openLinkInChrome{
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [chromeApp setLaunchArguments:@[[self webPageURLWithRedirection:NO]]];
    
    if (chromeApp.state == XCUIApplicationStateNotRunning) { // If Chrome is not running, launch now
        [chromeApp launch];
    } else {
        [chromeApp activate]; // Activate Chrome
        if([chromeApp waitForState:XCUIApplicationStateRunningForeground timeout:6])
        {
            XCUIElement *element = [chromeApp.windows.textFields elementBoundByIndex:0];
            [element click];
            sleep(1.0);
            [element typeText:[self webPageURLWithRedirection:NO]];
            sleep(1.0);
            [element typeKey:XCUIKeyboardKeyReturn modifierFlags:XCUIKeyModifierNone];
            sleep(1.0);
        }
        else {
            XCTFail(@"Could not launch Chrome.");
        }
    }
    
    XCUIElement *element = [chromeApp.windows.textFields elementBoundByIndex:0];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
}

- (void)t1estChromeAllowAppLaunch {
    
    [self openLinkInChrome];
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    XCUIElement *openButton = [[[[chromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];

    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:NO];
        [chromeApp activate];
        
    } else {
        XCTFail("Application not launched");
    }
}

- (void)t1estChromeCancelAppLaunch {
    
    [self openLinkInChrome];
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    XCUIElement *cancelButton = [[[[chromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:0] ;
    [cancelButton click];

    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:NO];
        [chromeApp activate];
        XCTFail("Application Launched");
        
    }
}

- (void)testSfariAllowAppLaunch {
    
}

- (void)testSafariCancelAppLaunch {
    
}
@end
