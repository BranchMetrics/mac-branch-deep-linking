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
    
    [chromeApp setLaunchArguments:@[[self webPageURLWithRedirection:enabled]]];
    
    if (chromeApp.state == XCUIApplicationStateNotRunning) { // If Chrome is not running, launch now
        [chromeApp launch];
    } else {
        [chromeApp activate]; // Activate Chrome
        if([chromeApp waitForState:XCUIApplicationStateRunningForeground timeout:6])
        {
            XCUIElement *element = [chromeApp.windows.textFields elementBoundByIndex:0];
            [element click];
            sleep(1.0);
            [element typeText:[self webPageURLWithRedirection:enabled]];
            sleep(1.0);
            [element typeKey:XCUIKeyboardKeyReturn modifierFlags:XCUIKeyModifierNone];
            sleep(1.0);
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
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);

    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];

    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        [googleChromeApp activate];
        
    } else {
        XCTFail("Application not launched");
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

-(void) openURLInNewTabWithRedirection:(BOOL)enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        
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

-(void) openURLInNewWindowWithRedirection:(BOOL) enabled browserCold:(BOOL) bCold appCold:(BOOL) aCold  trackDisabled:(BOOL) disable {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    [self setUpWithRedirection:enabled browserCold:bCold appCold:aCold trackDisabled:disable];
    
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
 
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
        
    } else {
        XCTFail("Application not launched");
    }
    
}

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
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:enabled];
    } else {
        XCTFail("Application not launched");
    }
    
}

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

-(void) terminateChrome {
    [[[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"] terminate];
}

@end
