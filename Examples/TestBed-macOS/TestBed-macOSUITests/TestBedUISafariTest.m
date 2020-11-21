//
//  TestBedUISafariTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/7/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

#define SLEEP_TIME_CLICK_BIG        3
#define SLEEP_TIME_CLICK_SMALL      1


@interface TestBedUISafariTest : TestBedUITest {
    XCTestExpectation *expectationForAppLaunch;
}
@end

@implementation TestBedUISafariTest

void *kSafariKVOContext = (void*)&kSafariKVOContext;

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

-(void) setUpWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    // Check and Set Browser State - Cold or Warm
//    if (bCold) { // Terminate Safari and launch new
//        if (safariApp.state != XCUIApplicationStateNotRunning)
//            [self terminateSafari];
//        [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
//        [safariApp launch];
//    }
//    else {
//
//        [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
//        if (safariApp.state == XCUIApplicationStateNotRunning) { // If Safari is not running, launch now
//            [safariApp launch];
//        }
//        [safariApp activate]; // Activate Safari
//    }
    
    if (bCold) { // Terminate Safari and launch new
            if (safariApp.state != XCUIApplicationStateNotRunning)
                [self terminateSafari];
        }
        
    
        [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
        if (safariApp.state == XCUIApplicationStateNotRunning) { // If Safari is not running, launch now
            [safariApp launch];
        }
        else{
            [safariApp activate]; // Activate Safari
            if([safariApp waitForState:XCUIApplicationStateRunningForeground timeout:6])
            {
            [safariApp  typeKey:@"N"
               modifierFlags: XCUIKeyModifierCommand];
            sleep(1.0);
            [safariApp typeText:[self testWebPageURLWithRedirection:enabled]];
            [safariApp typeKey:XCUIKeyboardKeyEnter
               modifierFlags:XCUIKeyModifierNone];
            }
            else {
                XCTFail(@"Could not launch Safari.");
            }
//            sleep(3.0);
        }
       
    
    
    // Check and Set TestBed State - Cold Warm
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    if (aCold) { // Terminate Safari and launch new
        if (testBedApp.state != XCUIApplicationStateNotRunning)
            [self terminateTestBed];
    }
    else {
        if (testBedApp.state == XCUIApplicationStateNotRunning) { // If Safari is not running, launch now
            [testBedApp launch];
            self.appLaunched = TRUE;
        }
//        else {
        //    [testBedApp activate]; // Activate Safari
        //}
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

-(void) openURLInSafariWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
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
        // TODO - take screen shot.
    }
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
        // TODO - take screen shot.
    }
}

-(void) testSafari1ColdBrowserColdAppClickURLTrackDisabled0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari2ColdBrowserWarmAppClickURLTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari3WarmBrowserColdAppClickURLTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari4WarmBrowserWarmAppClickURLTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari5ColdBrowserColdAppClickURLTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari6ColdBrowserWarmAppClickURLTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari7WarmBrowserColdAppClickURLTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari8WarmBrowserWarmAppClickURLTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari9ColdBrowserColdAppClickURLTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari10ColdBrowserWarmAppClickURLTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari11WarmBrowserColdAppClickURLTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari12WarmBrowserWarmAppClickURLTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari13ColdBrowserColdAppClickURLTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari14ColdBrowserWarmAppClickURLTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari15WarmBrowserColdAppClickURLTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari16WarmBrowserWarmAppClickURLTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

//-(void) testOpenURLInSafari {
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
//           @try {
//                
//                [self terminateTestBed];
//                [self terminateSafari];
//                [self openURLInSafariWithRedirection:enableRedirection];
//                
//            } @finally {
//                
//            }
//        }];
//        
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//           @try {
//                
//                [self terminateSafari];
//                [self openURLInSafariWithRedirection:enableRedirection];
//                
//            } @finally {
//                
//            }
//        }];
//        
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//           @try {
//                
//                [self terminateTestBed];
//                [self openURLInSafariWithRedirection:enableRedirection];
//                
//            } @finally {
//                
//            }
//        }];
//        
//        // Warm Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
//            @try {
//                [self openURLInSafariWithRedirection:enableRedirection];
//                
//            } @finally {
//                
//            }
//        }];
//    }
//}

-(void) openURLInNewTabWithRedirection:(BOOL) enabled {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(SLEEP_TIME_CLICK_BIG);
    
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 rightClick];
    
    sleep(SLEEP_TIME_CLICK_SMALL);
    
    [element2 typeKey:XCUIKeyboardKeyRightArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyEnter
        modifierFlags:XCUIKeyModifierNone];
    
    sleep(SLEEP_TIME_CLICK_SMALL);
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    //[safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
//
//    XCTAssertTrue([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:30]);
//    self.appLaunched = TRUE;
//    [self validateDeepLinkDataForRedirectionEnabled:enabled];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    
}

-(void) test1OpenURLInSafariInNewTab{
    
    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
    
    for (int i = 0; i < 4; i++) {
        
        BOOL enableTracking = options[i][0];
        
        if (enableTracking) {
            [self enableTracking];
        }
        else {
            [self disableTracking];
        }
        
        __block BOOL enableRedirection = options[i][1];
        
        // Cold Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateTestBed];
                [self terminateSafari];
                [self openURLInNewTabWithRedirection:enableRedirection];
            } @finally {
                
            }
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateSafari];
                [self openURLInNewTabWithRedirection:enableRedirection];
            } @finally {
                
            }
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateTestBed];
                [self openURLInNewTabWithRedirection:enableRedirection];
            } @finally {
                
            }
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self openURLInNewTabWithRedirection:enableRedirection];
            } @finally {
                
            }
        }];
    }
}

-(void) openURLInNewWindowWithRedirection:(BOOL) enabled {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(3);
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 rightClick];
    
    sleep(1.0);
    
    [element2 typeKey:XCUIKeyboardKeyRightArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyEnter
        modifierFlags:XCUIKeyModifierNone];
    
    sleep(1);
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
}

-(void) testOpenURLInSafariInNewWindow{
    
    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
    
    for (int i = 0; i < 4; i++) {
        
        BOOL enableTracking = options[i][0];
        
        if (enableTracking) {
            [self enableTracking];
        }
        else {
            [self disableTracking];
        }
        
        [self terminateTestBed];
        sleep(3);
        
        __block BOOL enableRedirection = options[i][1];
        
        // Cold Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateTestBed];
                [self terminateSafari];
                [self openURLInNewWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateSafari];
                [self openURLInNewWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateTestBed];
                [self openURLInNewWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self openURLInNewWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
    }
}

-(void) openURLInPrivateWindowWithRedirection:(BOOL) enabled {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(3);
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 rightClick];
    
    sleep(1.0);
    
    [element2 typeKey:XCUIKeyboardKeyRightArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyEnter
        modifierFlags:XCUIKeyModifierOption];
    
    sleep(3);
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
}

-(void) testOpenURLInSafariInPrivateWindow {
    
    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
    
    for (int i = 0; i < 4; i++) {
        
        BOOL enableTracking = options[i][0];
        
        if (enableTracking) {
            [self enableTracking];
        }
        else {
            [self disableTracking];
        }
        
        __block BOOL enableRedirection = options[i][1];
        
        // Cold Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateTestBed];
                [self terminateSafari];
                [self openURLInPrivateWindowWithRedirection:enableRedirection];
            } @finally {
                
            }
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self terminateSafari];
                [self openURLInPrivateWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                
                [self terminateTestBed];
                [self openURLInPrivateWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            @try {
                [self openURLInPrivateWindowWithRedirection:enableRedirection];
                
            } @finally {
                
            }
        }];
    }
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
    if (context != kSafariKVOContext)
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
