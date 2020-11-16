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

-(void) terminateTestBed {
    [[[XCUIApplication alloc] init] terminate];
}

-(void) terminateSafari {
    [[[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"] terminate];
}

-(NSString *) testWebPageURL{
    return [NSString stringWithFormat:@"%@%@" , [[NSBundle mainBundle] bundlePath] , @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestWebPage.html" ];
}

-(void) openURLInSafari {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURL]]];
    [safariApp launch];
    [safariApp activate];
    
    sleep(3);
    
    XCUIElement *element2 = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [element2 click];
    XCUIElement *confirmationToggleButton = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ];
    if (confirmationToggleButton.exists) {
        [confirmationToggleButton click];
    }
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kSafariKVOContext];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

-(void) testOpenURLInSafari{
    
//    int options[4][2] = {{0,0}, {0,1}, {1,0}, {1,1}}; // TRACKING_ENABLED X REDIRECTION_ENABLED
//
//    for (int i = 0; i < 4; i++) {
//        NSLog(@"Tracking Enabled: %d Redirection Enabled: %d" , options[i][0], options[i][1]);
//    }
    
    int options[2] = {1,0}; // TRACKING_ENABLED
    
    for (int i = 0; i < 2; i++) {
        
        if (options[i]) {
            [self enableTracking];
        }
        else {
            [self disableTracking];
        }
        
        // Cold Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppClickURLTrack%d", options[i]] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInSafari];
            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInSafari];
            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInSafari];
            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
            [self openURLInSafari];
            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInNewTab {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURL]]];
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
    [element2 typeKey:XCUIKeyboardKeyEnter
       modifierFlags:XCUIKeyModifierNone];
    
    
    [[[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ] click];
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew // maybe | NSKeyValueObservingOptionInitial
                                       context:kSafariKVOContext];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

-(void) applicationActivated:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
     
    NSLog( @"=>=>=>%@", app.localizedName);
}

-(void) testOpenURLInSafariInNewTab{

    // Cold Browser & Cold App
    [XCTContext runActivityNamed:@"ColdBrowserColdAppURLInNewTab" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self terminateSafari];
        [self openURLInNewTab];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Cold Browser & Warm App
    [XCTContext runActivityNamed:@"ColdBrowserWarmAppURLInNewTab" block:^(id<XCTActivity> activity) {
        [self terminateSafari];
        [self openURLInNewTab];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Warm Browser & Cold App
    [XCTContext runActivityNamed:@"WarmBrowserColdAppURLInNewTab" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self openURLInNewTab];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Warm Browser & Warm App
    [XCTContext runActivityNamed:@"WarmBrowserWarmAppURLInNewTab" block:^(id<XCTActivity> activity) {
        [self openURLInNewTab];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];
}

-(void) openURLInNewWindow {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURL]]];
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
    
    
    [[[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ] click];
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kSafariKVOContext];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

-(void) testOpenURLInSafariInNewWindow{
    
    // Cold Browser & Cold App
    [XCTContext runActivityNamed:@"ColdBrowserColdAppURLInNewWindow" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self terminateSafari];
        [self openURLInNewWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Cold Browser & Warm App
    [XCTContext runActivityNamed:@"ColdBrowserWarmAppURLInNewWindow" block:^(id<XCTActivity> activity) {
        [self terminateSafari];
        [self openURLInNewWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Warm Browser & Cold App
    [XCTContext runActivityNamed:@"WarmBrowserColdAppURLInNewWindow" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self openURLInNewWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];
    
    // Warm Browser & Warm App
    [XCTContext runActivityNamed:@"WarmBrowserWarmAppURLInNewWindow" block:^(id<XCTActivity> activity) {
        [self openURLInNewWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];
}

-(void) openURLInPrivateWindow {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp setLaunchArguments:@[[self testWebPageURL]]];
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
    
    
    [[[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ] click];
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kSafariKVOContext];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

-(void) testOpenURLInSafariInPrivateWindow {
    
    // Cold Browser & Cold App
    [XCTContext runActivityNamed:@"ColdBrowserColdAppURLInPrivateWindow" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self terminateSafari];
        [self openURLInPrivateWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Cold Browser & Warm App
    [XCTContext runActivityNamed:@"ColdBrowserWarmAppURLInPrivateWindow" block:^(id<XCTActivity> activity) {
        [self terminateSafari];
        [self openURLInPrivateWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];

    // Warm Browser & Cold App
    [XCTContext runActivityNamed:@"WarmBrowserColdAppURLInPrivateWindow" block:^(id<XCTActivity> activity) {
        [self terminateTestBed];
        [self openURLInPrivateWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];
    
    // Warm Browser & Warm App
    [XCTContext runActivityNamed:@"WarmBrowserWarmAppURLInPrivateWindow" block:^(id<XCTActivity> activity) {
        [self openURLInPrivateWindow];
        XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
    }];
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context != kSafariKVOContext)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    NSLog(@"keyPath : 44444444 %@" , keyPath);
    if ([keyPath isEqualToString:@"runningApplications"])
    {
        for (NSRunningApplication * application in NSWorkspace.sharedWorkspace.runningApplications) {
                if ([application.bundleIdentifier isEqualToString:@"io.branch.sdk.TestBed-Mac"]) {
                    [[NSWorkspace sharedWorkspace] removeObserver:self forKeyPath:@"runningApplications"];
                    [expectationForAppLaunch fulfill];
                   //ND  [application terminate];
                    break;
                }
            }
    }
}
@end
