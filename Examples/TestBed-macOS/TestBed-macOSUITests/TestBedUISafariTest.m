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
    
    if (bCold) { // Terminate Safari and launch new
        if (safariApp.state != XCUIApplicationStateNotRunning)
            [self terminateSafari];
    }
    
    [safariApp setLaunchArguments:@[[self webPageURLWithRedirection:enabled]]];
    if (safariApp.state == XCUIApplicationStateNotRunning) { // If Safari is not running, launch now
        [safariApp launch];
    } else {
        [safariApp activate]; // Activate Safari
        if([safariApp waitForState:XCUIApplicationStateRunningForeground timeout:6])
        {
            [safariApp  typeKey:@"N"
                  modifierFlags: XCUIKeyModifierCommand]; // Open New Window
            sleep(1.0);
            [safariApp typeText:[self webPageURLWithRedirection:enabled]];
            [safariApp typeKey:XCUIKeyboardKeyEnter
                 modifierFlags:XCUIKeyModifierNone];
        }
        else {
            XCTFail(@"Could not launch Safari.");
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

-(void) testSafari01ClickURLColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari02ClickURLColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari03ClickURLWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari04ClickURLWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari05ClickURLColdBrowserColdAppTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari06ClickURLColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari07ClickURLWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari08ClickURLWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari09ClickURLColdBrowserColdAppTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari10ClickURLColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari11ClickURLWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari12ClickURLWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInSafariWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari13ClickURLColdBrowserColdAppTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari14ClickURLColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari15ClickURLWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari16ClickURLWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInSafariWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) openURLInNewTabWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    NSOperatingSystemVersion minimumSupportedOSVersion = { .majorVersion = 10, .minorVersion = 15, .patchVersion = 0 };
    BOOL isSupported = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumSupportedOSVersion];
    
    if (isSupported) {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
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
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    }
    
}

-(void) testSafari17OpenURLInNewTabColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari18OpenURLInNewTabColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari19OpenURLInNewTabWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari20OpenURLInNewTabWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari21OpenURLInNewTabColdBrowserColdAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari22OpenURLInNewTabColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari23OpenURLInNewTabWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari24OpenURLInNewTabWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari25OpenURLInNewTabColdBrowserColdAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari26OpenURLInNewTabColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari27OpenURLInNewTabWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari28OpenURLInNewTabWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewTabWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari29OpenURLInNewTabColdBrowserColdAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari30OpenURLInNewTabColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari31OpenURLInNewTabWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari32OpenURLInNewTabWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewTabWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}


-(void) openURLInNewWindowWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
      NSOperatingSystemVersion minimumSupportedOSVersion = { .majorVersion = 10, .minorVersion = 15, .patchVersion = 0 };
      BOOL isSupported = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumSupportedOSVersion];
      
      if (isSupported) {
          
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    sleep(SLEEP_TIME_CLICK_BIG);
    
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
}

-(void) testSafari33OpenURLInNewWindowColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari34OpenURLInNewWindowColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari35OpenURLInNewWindowWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari36OpenURLInNewWindowWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari37OpenURLInNewWindowColdBrowserColdAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari38OpenURLInNewWindowColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari39OpenURLInNewWindowWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari40OpenURLInNewWindowWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari41OpenURLInNewWindowColdBrowserColdAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari42OpenURLInNewWindowColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari43OpenURLInNewWindowWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari44OpenURLInNewWindowWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInNewWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari45OpenURLInNewWindowColdBrowserColdAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari46OpenURLInNewWindowColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari47OpenURLInNewWindowWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari48OpenURLInNewWindowWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInNewWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) openURLInPrivWindowWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    NSOperatingSystemVersion minimumSupportedOSVersion = { .majorVersion = 10, .minorVersion = 15, .patchVersion = 0 };
      BOOL isSupported = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumSupportedOSVersion];
      
      if (isSupported) {
          
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    sleep(SLEEP_TIME_CLICK_BIG);
    
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
    [self takeScreenShot];
          
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
          [self takeScreenShot];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
        [self takeScreenShot];
    }
    [self takeScreenShot];
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        [self takeScreenShot];
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [safariApp activate];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
        
    } else {
        XCTFail("Application not launched");
    }
    }
}


-(void) testSafari49OpenURLInPrivWindowColdBrowserColdAppTrackDisabled0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari50OpenURLInPrivWindowColdBrowserWarmAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari51OpenURLInPrivWindowWarmBrowserColdAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari52OpenURLInPrivWindowWarmBrowserWarmAppTrack0Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari53OpenURLInPrivWindowColdBrowserColdAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari54OpenURLInPrivWindowColdBrowserWarmAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari55OpenURLInPrivWindowWarmBrowserColdAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:FALSE];
}

-(void) testSafari56OpenURLInPrivWindowWarmBrowserWarmAppTrack0Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:FALSE];
}

-(void) testSafari57OpenURLInPrivWindowColdBrowserColdAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari58OpenURLInPrivWindowColdBrowserWarmAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari59OpenURLInPrivWindowWarmBrowserColdAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari60OpenURLInPrivWindowWarmBrowserWarmAppTrack1Redirect0 {
    [self openURLInPrivWindowWithRedirection:FALSE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari61OpenURLInPrivWindowColdBrowserColdAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari62OpenURLInPrivWindowColdBrowserWarmAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:TRUE appCold:FALSE trackDisabled:TRUE];
}

-(void) testSafari63OpenURLInPrivWindowWarmBrowserColdAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:TRUE trackDisabled:TRUE];
}

-(void) testSafari64OpenURLInPrivWindowWarmBrowserWarmAppTrack1Redirect1 {
    [self openURLInPrivWindowWithRedirection:TRUE browserCold:FALSE appCold:FALSE trackDisabled:TRUE];
}

-(void) terminateSafari {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp activate];
    if (safariApp.state == XCUIApplicationStateRunningForeground) {
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierShift|XCUIKeyModifierCommand|XCUIKeyModifierOption];
    }
    [safariApp terminate];
}

@end
