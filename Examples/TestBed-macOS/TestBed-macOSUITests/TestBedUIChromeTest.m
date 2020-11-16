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

-(void) terminateTestBed {
    [[[XCUIApplication alloc] init] terminate];
}

-(void) terminateChrome {
    [[[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"] terminate];
}

-(NSString *) testWebPageURL{
    return [NSString stringWithFormat:@"%@%@" , [[NSBundle mainBundle] bundlePath] , @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestWebPage.html" ];
}

-(void) openURLInChrome {
    
    XCUIApplication *googleChromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    [googleChromeApp launch];
    [googleChromeApp activate];
    XCUIElement *element = [googleChromeApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:[self testWebPageURL]];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    NSLog(@"%@" , [element debugDescription]);
   // [element tap];
    
    sleep(1.0);
   // [[googleChromeApp.windows.webViews.links elementBoundByIndex:0] click];
   // NSLog(@"%@" , [[googleChromeApp windows] debugDescription])
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
                                       options:NSKeyValueObservingOptionNew // maybe | NSKeyValueObservingOptionInitial
                                       context:kChromeKVOContext];
    
    //XCTestExpectation *expectationForAppLaunch
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    NSArray *eles = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex];
   // NSArray *eles = [[googleChromeApp descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex ] ;
    for (int i = 0 ; i < eles.count ; i++)
    NSLog(@"%@", [eles[i] debugDescription] );
    XCUIElement *openButton = [[[[googleChromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
   // NSArray *eles = [[googleChromeApp descendantsMatchingType:XCUIElementTypeButton] allElementsBoundByIndex ] ;
    [openButton click];
   
    
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    
}

-(void) applicationActivated:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
     
    NSLog( @"=>=>=>%@", app.localizedName);
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
-(void) testOpenURLInChrome{
    
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
        
//        // Cold Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserColdAppClickURLTrack%d", options[i]] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self terminateChrome];
//            [self openURLInChrome];
//            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Cold Browser & Warm App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"ColdBrowserWarmAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
//            [self terminateChrome];
//            [self openURLInChrome];
//            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
//        // Warm Browser & Cold App
//        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserColdAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
//            [self terminateTestBed];
//            [self openURLInChrome];
//            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
//        }];
//
        // Warm Browser & Warm App
        [XCTContext runActivityNamed:[NSString stringWithFormat:@"WarmBrowserWarmAppClickURL%d", options[i]] block:^(id<XCTActivity> activity) {
            [self openURLInChrome];
            [self launchAppAndWaitForSessionStart];
            XCTAssertTrue([[self dataTextViewString] containsString:@ TESTBED_CLICK_LINK]);
        }];
    }
}

@end
