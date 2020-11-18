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

-(void) openURLInChromeWithRedirection:(BOOL)enabled {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    [googleChromeApp launch];
    [googleChromeApp activate];
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:[self testWebPageURLWithRedirection:enabled]];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    expectationForAppLaunch.assertForOverFulfill = NO;
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kChromeKVOContext];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
    for (int i = 0 ; i < eles.count ; i++)
    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
}

-(void) testOpenURLInChrome{
    
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
            [self openURLInChromeWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInChromeWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInChromeWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURLTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInChromeWithRedirection:enableRedirection];;
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInChromeInNewTabWithRedirection:(BOOL)enabled {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    [googleChromeApp launch];
    [googleChromeApp activate];
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:[self testWebPageURLWithRedirection:enabled]];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    expectationForAppLaunch.assertForOverFulfill = NO;
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kChromeKVOContext];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
    for (int i = 0 ; i < eles.count ; i++)
    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
}

-(void) testOpenURLInChromeInNewTab{
    
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
            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInChromeInNewTabWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewTabTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInChromeInNewTabWithRedirection:enableRedirection];;
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInChromeInNewWindowWithRedirection:(BOOL)enabled {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    [googleChromeApp launch];
    [googleChromeApp activate];
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:[self testWebPageURLWithRedirection:enabled]];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    expectationForAppLaunch.assertForOverFulfill = NO;
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kChromeKVOContext];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
    for (int i = 0 ; i < eles.count ; i++)
    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
}

-(void) testOpenURLInChromeInNewWindow{
    
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
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self terminateSafari];
            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInNewWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInChromeInNewWindowWithRedirection:enableRedirection];;
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

-(void) openURLInChromeInPrivateWindowWithRedirection:(BOOL)enabled {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    [googleChromeApp launch];
    [googleChromeApp activate];
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:[self testWebPageURLWithRedirection:enabled]];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierCommand|XCUIKeyModifierShift];
    sleep(1.0);
    
    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];
    expectationForAppLaunch.assertForOverFulfill = NO;
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kChromeKVOContext];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
    for (int i = 0 ; i < eles.count ; i++)
    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    
}

-(void) testOpenURLInChromeInPrivateWindow{
    
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
            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Cold Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateSafari];
            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Cold App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self terminateTestBed];
            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
        
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppOpenURLInPrivateWindowTrack%dRedirect%d", enableTracking, enableRedirection] block:^(id<XCTActivity> activity) {
            [self openURLInChromeInPrivateWindowWithRedirection:enableRedirection];;
            // Remove assestion for now XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}
-(void) applicationActivated:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
    NSLog( @"App Activated => %@", app.localizedName);
    if ([app.localizedName isEqualToString:@"TestBed-macOS"]) {
            [expectationForAppLaunch fulfill];
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
