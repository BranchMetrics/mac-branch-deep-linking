//
//  TestBedUISafariTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/7/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

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


-(void) openURLInSafariWithRedirection:(BOOL) enabled isWarm:(BOOL) warm {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(1);
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 click];
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    if (!warm) {
        expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
        
        [[NSWorkspace sharedWorkspace] addObserver:self
                                        forKeyPath:@"runningApplications"
                                           options:NSKeyValueObservingOptionNew
                                           context:kSafariKVOContext];
        
        [self waitForExpectationsWithTimeout:6.0 handler:nil];
    }
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
            sleep(1);
            [self terminateSafari];
            [self openURLInSafariWithRedirection:enableRedirection isWarm:FALSE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInSafariWithRedirection:enableRedirection isWarm:YES];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            sleep(1);
            [self openURLInSafariWithRedirection:enableRedirection isWarm:FALSE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInSafariWithRedirection:enableRedirection isWarm:FALSE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInNewTabWithRedirection:(BOOL) enabled isWarm:(BOOL) warm {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(1);
    
    if (safariApp.state == XCUIApplicationStateRunningForeground) {
        [safariApp typeKey:@"W" modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierOption];
    }
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 rightClick];
    
    [element2 typeKey:XCUIKeyboardKeyRightArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    
    [element2 typeKey:XCUIKeyboardKeyDownArrow
        modifierFlags:XCUIKeyModifierNone];
    [element2 typeKey:XCUIKeyboardKeyEnter
        modifierFlags:XCUIKeyModifierNone];
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    if (!warm) {
        expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
        
        [[NSWorkspace sharedWorkspace] addObserver:self
                                        forKeyPath:@"runningApplications"
                                           options:NSKeyValueObservingOptionNew // maybe | NSKeyValueObservingOptionInitial
                                           context:kSafariKVOContext];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
        [self waitForExpectationsWithTimeout:6.0 handler:nil];
    }
}

-(void) applicationActivated:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
    
    NSLog( @"=>=>=>%@", app.localizedName);
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
            [self openURLInNewTabWithRedirection:enableRedirection isWarm:FALSE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInNewTabWithRedirection:enableRedirection isWarm:TRUE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInNewTabWithRedirection:enableRedirection isWarm:FALSE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInNewTabWithRedirection:enableRedirection isWarm:TRUE];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInNewWindowWithRedirection:(BOOL) enabled isWarm:(BOOL) warm {
    
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
    
    if (!warm) {
    
        expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
        
        [[NSWorkspace sharedWorkspace] addObserver:self
                                        forKeyPath:@"runningApplications"
                                           options:NSKeyValueObservingOptionNew
                                           context:kSafariKVOContext];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
        [self waitForExpectationsWithTimeout:6.0 handler:nil];
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
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInNewWindowWithRedirection:enableRedirection isWarm:TRUE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];

        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInNewWindowWithRedirection:enableRedirection isWarm:FALSE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInNewWindowWithRedirection:enableRedirection isWarm:TRUE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInNewWindowWithRedirection:enableRedirection isWarm:FALSE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInPrivateWindowWithRedirection:(BOOL) enabled isWarm:(BOOL) warm {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURLWithRedirection:enabled]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(3);
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 rightClick];
    
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
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    
    if (!warm) {
        expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
        
        [[NSWorkspace sharedWorkspace] addObserver:self
                                        forKeyPath:@"runningApplications"
                                           options:NSKeyValueObservingOptionNew
                                           context:kSafariKVOContext];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
        [self waitForExpectationsWithTimeout:6.0 handler:nil];
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
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInPrivateWindowWithRedirection:enableRedirection isWarm:TRUE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInPrivateWindowWithRedirection:enableRedirection isWarm:FALSE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInPrivateWindowWithRedirection:enableRedirection isWarm:TRUE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInPrivateWindowWithRedirection:enableRedirection isWarm:FALSE];
            XCTAssertNotNil([self dataTextViewString]);
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
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