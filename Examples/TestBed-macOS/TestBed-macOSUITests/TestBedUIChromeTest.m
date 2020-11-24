//
//  TestBedUIChromeTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/11/20.
//  Copyright © 2020 Branch. All rights reserved.
//


#import "TestBedUITest.h"
#import "TestBedUIUtils.h"


@interface TestBedUIChromeTest : TestBedUITest{
    XCTestExpectation *expectationForAppLaunch;
}
@end

@implementation TestBedUIChromeTest

void *kChromeKVOContext = (void*)&kChromeKVOContext;

- (void)setUp {
   [super setUp];
}

- (void)tearDown {
   [super tearDown];
}

-(void) setUpWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    if (bCold) { // Terminate Chrome and launch new
        if (chromeApp.state != XCUIApplicationStateNotRunning)
            [self terminateChrome];
    }
    
    [chromeApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    if (chromeApp.state == XCUIApplicationStateNotRunning) { // If Chrome is not running, launch now
        [chromeApp launch];
    } else {
        [chromeApp activate]; // Activate Chrome
        if([chromeApp waitForState:XCUIApplicationStateRunningForeground timeout:6])
        {
//            [chromeApp  typeKey:@"N"
//                  modifierFlags: XCUIKeyModifierCommand]; // Open New Window
//            sleep(1.0);
//            [chromeApp typeText:[self testWebPageURLWithRedirection:enabled]];
//            [chromeApp typeKey:XCUIKeyboardKeyEnter
//                 modifierFlags:XCUIKeyModifierNone];
        }
        else {
            XCTFail(@"Could not launch Chrome.");
        }
    }

    // Check and Set TestBed State - Cold Warm
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    
    if (aCold) { // Terminate TestBed and launch new
        if (testBedApp.state != XCUIApplicationStateNotRunning)
            [self terminateTestBed];
    }
    else {
        if (testBedApp.state == XCUIApplicationStateNotRunning) { // If TestBed is not running, launch now
            [testBedApp launch];
            self.appLaunched = TRUE;
        }
    }
    
    // Disable / Enable Tracking
    if ( disable ) {
        if (self.trackingState != TRACKING_DISABLED) {
            [self disableTracking];
        }
    }
    else {
        if (self.trackingState != TRACKING_ENABLED) {
            [self enableTracking];
        }
    }
    
}

-(void) openURLInChromeWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
//    [element click];
//    sleep(1.0);
//    [element typeText:[self testWebPageURLWithRedirection:enabled]];
//    sleep(1.0);
//    [element typeKey:XCUIKeyboardKeyReturn
//       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
//
//    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
//    expectationForAppLaunch.assertForOverFulfill = NO;
//
//    [[NSWorkspace sharedWorkspace] addObserver:self
//                                    forKeyPath:@"runningApplications"
//                                       options:NSKeyValueObservingOptionNew
//                                       context:kChromeKVOContext];
//
//    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
  //  NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
//    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [googleChromeApp activate];
        //[safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
        // TODO - take screen shot.
    }
    
}

-(void) testChrome01ClickURLColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome02ClickURLColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome03ClickURLWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome04ClickURLWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome05ClickURLColdBrowserColdAppTrack0Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome06ClickURLColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome07ClickURLWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome08ClickURLWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome09ClickURLColdBrowserColdAppTrack1Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome10ClickURLColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome11ClickURLWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome12ClickURLWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInChromeWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome13ClickURLColdBrowserColdAppTrack1Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome14ClickURLColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome15ClickURLWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome16ClickURLWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInChromeWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

//-(void) testOpenURLInChrome{
//
//    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
//
//    for (int i = 0; i < 4; i++) {
//
//        BOOL enableTracking = options[i][0];
//
//        if (enableTracking) {
//            [self enableTracking];
//        }
//        else {
//            [self disableTracking];
//        }
//
//        __block BOOL enableRedirection = options[i][1];
//
//        // Cold Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self terminateSafari];
//            [self openURLInChromeWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateSafari];
//            [self openURLInChromeWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self openURLInChromeWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self openURLInChromeWithRedirection:enableRedirection];;
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//    }
//}

-(void) openURLInNewTabWithRedirection:(BOOL)enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
//    [element click];
//    sleep(1.0);
//    [element typeText:[self testWebPageURLWithRedirection:enabled]];
//    sleep(1.0);
//    [element typeKey:XCUIKeyboardKeyReturn
//       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
//    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
//    expectationForAppLaunch.assertForOverFulfill = NO;
//
//    [[NSWorkspace sharedWorkspace] addObserver:self
//                                    forKeyPath:@"runningApplications"
//                                       options:NSKeyValueObservingOptionNew
//                                       context:kChromeKVOContext];
//
//    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
//
//    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
//    for (int i = 0 ; i < eles.count ; i++)
//    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
//        [safariApp activate];
//        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    
}


-(void) testChrome17OpenURLInNewTabColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome18OpenURLInNewTabColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome19OpenURLInNewTabWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome20OpenURLInNewTabWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome21OpenURLInNewTabColdBrowserColdAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome22OpenURLInNewTabColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome23OpenURLInNewTabWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome24OpenURLInNewTabWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome25OpenURLInNewTabColdBrowserColdAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome26OpenURLInNewTabColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome27OpenURLInNewTabWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome28OpenURLInNewTabWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome29OpenURLInNewTabColdBrowserColdAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome30OpenURLInNewTabColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome31OpenURLInNewTabWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome32OpenURLInNewTabWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}


//-(void) t1estOpenURLInChromeInNewTab{
//
//    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
//
//    for (int i = 0; i < 4; i++) {
//
//        BOOL enableTracking = options[i][0];
//
//        if (enableTracking) {
//            [self enableTracking];
//        }
//        else {
//            [self disableTracking];
//        }
//
//        __block BOOL enableRedirection = options[i][1];
//
//        // Cold Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self terminateSafari];
//            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateSafari];
//            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self openURLInChromeInNewTabWithRedirection:enableRedirection];;
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//    }
//}

-(void) openURLInNewWindowWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
//    [element click];
//    sleep(1.0);
//    [element typeText:[self testWebPageURLWithRedirection:enabled]];
//    sleep(1.0);
//    [element typeKey:XCUIKeyboardKeyReturn
//       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
//    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
//    expectationForAppLaunch.assertForOverFulfill = NO;
//
//    [[NSWorkspace sharedWorkspace] addObserver:self
//                                    forKeyPath:@"runningApplications"
//                                       options:NSKeyValueObservingOptionNew
//                                       context:kChromeKVOContext];
//
//    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
//
//    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
//    for (int i = 0 ; i < eles.count ; i++)
//    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
//    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
//        [safariApp activate];
//        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    
}
//
//-(void) tes1t1OpenURLInChromeInNewWindow{
//
//    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
//
//    for (int i = 0; i < 4; i++) {
//
//        BOOL enableTracking = options[i][0];
//
//        if (enableTracking) {
//            [self enableTracking];
//        }
//        else {
//            [self disableTracking];
//        }
//
//        __block BOOL enableRedirection = options[i][1];
//
//        // Cold Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self terminateSafari];
//            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateSafari];
//            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];;
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//    }
//}


-(void) testChrome33OpenURLInNewWindowColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome34OpenURLInNewWindowColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome35OpenURLInNewWindowWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome36OpenURLInNewWindowWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome37OpenURLInNewWindowColdBrowserColdAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome38OpenURLInNewWindowColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome39OpenURLInNewWindowWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome40OpenURLInNewWindowWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome41OpenURLInNewWindowColdBrowserColdAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome42OpenURLInNewWindowColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome43OpenURLInNewWindowWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome44OpenURLInNewWindowWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome45OpenURLInNewWindowColdBrowserColdAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome46OpenURLInNewWindowColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome47OpenURLInNewWindowWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome48OpenURLInNewWindowWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) openURLInPrivWindowWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
//    [element click];
//    sleep(1.0);
//    [element typeText:[self testWebPageURLWithRedirection:enabled]];
//    sleep(1.0);
//    [element typeKey:XCUIKeyboardKeyReturn
//       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
//    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
//    expectationForAppLaunch.assertForOverFulfill = NO;
//
//    [[NSWorkspace sharedWorkspace] addObserver:self
//                                    forKeyPath:@"runningApplications"
//                                       options:NSKeyValueObservingOptionNew
//                                       context:kChromeKVOContext];
//
//    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
//
//    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
//    for (int i = 0 ; i < eles.count ; i++)
//    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
//    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
//        [safariApp activate];
//        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    
}

//-(void) te1stOpenURLInChromeInPrivateWindow{
//
//    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
//
//    for (int i = 0; i < 4; i++) {
//
//        BOOL enableTracking = options[i][0];
//
//        if (enableTracking) {
//            [self enableTracking];
//        }
//        else {
//            [self disableTracking];
//        }
//
//        __block BOOL enableRedirection = options[i][1];
//
//        // Cold Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self terminateSafari];
//            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateSafari];
//            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];;
//            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//    }
//}
//-(void) applicationActivated:(NSNotification *)notification {
//    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
//    NSLog( @"App Activated => %@", app.localizedName);
//    if ([app.localizedName isEqualToString:@"TestBed-macOS"]) {
//            [expectationForAppLaunch fulfill];
//    }
//}



-(void) testChrome49OpenURLInPrivWindowColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome50OpenURLInPrivWindowColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome51OpenURLInPrivWindowWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome52OpenURLInPrivWindowWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome53OpenURLInPrivWindowColdBrowserColdAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome54OpenURLInPrivWindowColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome55OpenURLInPrivWindowWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testChrome56OpenURLInPrivWindowWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testChrome57OpenURLInPrivWindowColdBrowserColdAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome58OpenURLInPrivWindowColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome59OpenURLInPrivWindowWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome60OpenURLInPrivWindowWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome61OpenURLInPrivWindowColdBrowserColdAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome62OpenURLInPrivWindowColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testChrome63OpenURLInPrivWindowWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testChrome64OpenURLInPrivWindowWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

- (void) validateDeepLinkDataForRedirectionEnabled:(bool)enabled {
    
    NSMutableString *deepLinkDataString = [[NSMutableString alloc] initWithString:[self dataTextViewString]] ;
    
    XCTAssertTrue([deepLinkDataString isNotEqualTo:@""]);
    
    [deepLinkDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
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

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context != kChromeKVOContext)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"runningApplications"])
    {
        for (NSRunningApplication * application in NSWorkspace.sharedWorkspace.runningApplications) {
                if ([application.bundleIdentifier isEqualToString:@"io.branch.sdk.TestBed-Mac"]) {
                    [[NSWorkspace sharedWorkspace] removeObserver:self forKeyPath:@"runningApplications"];
                    [expectationForAppLaunch fulfill];
                   
                    break;
                }
            }
    }
}
@end
