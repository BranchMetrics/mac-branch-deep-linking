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


-(void) openURLInSafariWithRedirection:(BOOL) enabled {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(SLEEP_TIME_CLICK_BIG);
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 click];
    sleep(SLEEP_TIME_CLICK_BIG);
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    XCTAssertTrue([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:12]);
    self.appLaunched = TRUE;
    [self validateDeepLinkData];
}

-(void) testOpenURLInSafari{
    
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
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInSafariWithRedirection:enableRedirection];
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInSafariWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInSafariWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInSafariWithRedirection:enableRedirection];;
            XCTAssertNotNil([self dataTextViewString]);
        }];
    }
}

-(void) openURLInNewTabWithRedirection:(BOOL) enabled {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(SLEEP_TIME_CLICK_BIG);
    
    if (safariApp.state == XCUIApplicationStateRunningForeground) {
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
    }
    
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
    
    XCTAssertTrue([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:12]);
    self.appLaunched = TRUE;
    [self validateDeepLinkData];
}

-(void) testOpenURLInSafariInNewTab{
    
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
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInNewTabWithRedirection:enableRedirection];
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInNewTabWithRedirection:enableRedirection];
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInNewTabWithRedirection:enableRedirection];
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInNewTabWithRedirection:enableRedirection];
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
    
    XCTAssertTrue([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:12]);
    self.appLaunched = TRUE;
    [self validateDeepLinkData];
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
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInNewWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];

        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInNewWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInNewWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInNewWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
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
    
    XCTAssertTrue([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:12]);
    self.appLaunched = TRUE;
    [self validateDeepLinkData];
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
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInPrivateWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInPrivateWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInPrivateWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInPrivateWindowWithRedirection:enableRedirection];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

- (void) validateDeepLinkData {
    
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
    XCTAssertEqualObjects(deepLinkDataDictionary[@"~referring_link"], @"https://testbed-mac.app.link/ODYeswaVWM");
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
