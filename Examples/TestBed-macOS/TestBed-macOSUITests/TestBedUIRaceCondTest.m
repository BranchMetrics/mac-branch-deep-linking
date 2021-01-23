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
    
    [chromeApp setLaunchArguments:@[[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestRaceConditionWebPage.html"]]];
    
    [chromeApp launch];
    
    XCUIElement *element = [chromeApp.windows.textFields elementBoundByIndex:0];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyTab
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
    [element typeKey:XCUIKeyboardKeyReturn
       modifierFlags:XCUIKeyModifierNone];
    sleep(1.0);
}

- (void)testChromeAllowAppLaunch {
    
    // Terminate testBedApp if its running.
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    
    if (testBedApp.state != XCUIApplicationStateNotRunning)
        [testBedApp terminate];
    
    [self openLinkInChrome];
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    XCUIElement *openButton = [[[[chromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] ;
    [openButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] != NO) {
        self.appLaunched = TRUE;
        //[self validateDeepLinkDataForRedirectionEnabled:NO];
        [chromeApp activate];
        sleep(10);
        NSDictionary* errorDict;
        NSAppleEventDescriptor* returnDescriptor = NULL;
        
        NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                       @"\
                                       tell application \"Google Chrome\" to activate\n\
                                       tell application \"Google Chrome\"\n\
                                       tell active tab of front window\n\
                                       set x to execute javascript (\"document.getElementById('info').textContent ;\")\n\
                                       end tell\n\
                                       end tell\n\
                                       return x" ];
        
        returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
        
        NSLog(@"returnDescriptor : %@" , [returnDescriptor stringValue] );
        if (returnDescriptor != NULL)
        {
            // successful execution
            if (kAENullEvent != [returnDescriptor descriptorType])
            {
                [self validateDeepLinkData:[returnDescriptor stringValue] IfAppLanuched:YES];
                return;
            }
        }
        NSLog(@"Error : %@" , [errorDict description] );
        XCTFail(@"Test Failed!");
    } else {
        XCTFail("Application not launched");
    }
}


- (void) validateDeepLinkData:(NSString *) deepLinkData IfAppLanuched:(BOOL)launched {
    
    NSMutableString *deepLinkDataString = [[NSMutableString alloc] initWithString:deepLinkData] ;
    
    XCTAssertTrue([deepLinkDataString isNotEqualTo:@""]);
    
    [deepLinkDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    //Data received from server is not properly formatted. So adding quotes here. Will be removed later on when it will be fixed.
    [deepLinkDataString replaceOccurrencesOfString:@"website" withString:@"\"website\"" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"message :" withString:@"\"message\" :" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"MacSDK," withString:@"\"message\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"QuickLink," withString:@"\"message\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"marketing," withString:@"\"marketing\"," options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    NSError *error;
    NSDictionary *wholeDictionary = [NSJSONSerialization JSONObjectWithData: [ deepLinkDataString dataUsingEncoding:NSUTF8StringEncoding ] options:0 error:&error];
    
    NSDictionary *deepLinkDataDictionary = [NSJSONSerialization JSONObjectWithData: [ wholeDictionary[@"data"] dataUsingEncoding:NSUTF8StringEncoding ] options:0 error:&error];
    if (launched) {
        XCTAssertNotEqualObjects(deepLinkDataDictionary[@"+match_guaranteed"], @1 );
        XCTAssertNotEqualObjects(deepLinkDataDictionary[@"~referring_link"], @TESTBED_CLICK_LINK_RACE_CONDN);
    } else {
        XCTAssertEqualObjects(deepLinkDataDictionary[@"+match_guaranteed"], @1 );
        XCTAssertEqualObjects(deepLinkDataDictionary[@"~referring_link"], @TESTBED_CLICK_LINK_RACE_CONDN);
    }
}
- (void)testChromeCancelAppLaunch {
    
    // Terminate testBedApp if its running.
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    
    if (testBedApp.state != XCUIApplicationStateNotRunning)
        [testBedApp terminate];
    
    [self openLinkInChrome];
    
    XCUIApplication *chromeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.google.Chrome"];
    
    XCUIElement *cancelButton = [[[[chromeApp windows ] elementBoundByIndex:0] descendantsMatchingType:XCUIElementTypeButton] elementBoundByIndex:0] ;
    [cancelButton click];
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:9] != NO) {
        
        self.appLaunched = TRUE;
        [self validateDeepLinkDataForRedirectionEnabled:NO];
        [chromeApp activate];
        XCTFail("Application Launched");
        
    } else {
        
        NSDictionary* errorDict;
        NSAppleEventDescriptor* returnDescriptor = NULL;
        
        NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                       @"\
                                       tell application \"Google Chrome\" to activate\n\
                                       tell application \"Google Chrome\"\n\
                                       tell active tab of front window\n\
                                       set x to execute javascript (\"document.getElementById('info').textContent ;\")\n\
                                       end tell\n\
                                       end tell\n\
                                       return x" ];
        
        returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
        
        NSLog(@"returnDescriptor : %@" , [returnDescriptor stringValue] );
        if (returnDescriptor != NULL)
        {
            // successful execution
            if (kAENullEvent != [returnDescriptor descriptorType])
            {
                [self validateDeepLinkData:[returnDescriptor stringValue] IfAppLanuched:NO];
                return;
            }
        }
        NSLog(@"Error : %@" , [errorDict description] );
        XCTFail(@"Test Failed!");
    }
}

-(void)openLinkInSafari{
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    [safariApp setLaunchArguments:@[[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/PlugIns/TestBed-macOSUITests.xctest/Contents/Resources/TestRaceConditionWebPage.html"]]];
    [safariApp launch];
    
    sleep(6);
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink click];
    sleep(3);
}

- (void)testSfariAllowAppLaunch {
    // Terminate testBedApp if its running.
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    
    if (testBedApp.state != XCUIApplicationStateNotRunning)
        [testBedApp terminate];
    
    [self openLinkInSafari];
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
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
        //[self validateDeepLinkDataForRedirectionEnabled:NO];
        [safariApp activate];
        sleep(10);
        NSDictionary* errorDict;
        NSAppleEventDescriptor* returnDescriptor = NULL;
        
        NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                       @"\
                                       tell application \"Safari\" to activate\n\
                                       tell application \"Safari\"\n\
                                       tell current tab of front window\n\
                                       set x to do javascript (\"document.getElementById('info').textContent ;\")\n\
                                       end tell\n\
                                       end tell\n\
                                       return x" ];
        
        returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
        
        NSLog(@"returnDescriptor : %@" , [returnDescriptor stringValue] );
        
        if (returnDescriptor != NULL)
        {
            // successful execution
            if (kAENullEvent != [returnDescriptor descriptorType])
            {
                [self validateDeepLinkData:[returnDescriptor stringValue] IfAppLanuched:YES];
                return;
            }
        }
        NSLog(@"Error : %@" , [errorDict description] );
        XCTFail(@"Test Failed!");
    } else {
        XCTFail("Application not launched");
    }
}

- (void)testSafariCancelAppLaunch {
    // Terminate testBedApp if its running.
    XCUIApplication *testBedApp = [[XCUIApplication alloc] init];
    
    if (testBedApp.state != XCUIApplicationStateNotRunning)
        [testBedApp terminate];
    
    [self openLinkInSafari];
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    XCUIElement *toggleElement = [[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:0 ];
    if ([toggleElement waitForExistenceWithTimeout:12] != NO) {
        [toggleElement click];
    }
    else {
        NSLog(@"Toggle Element(TestBed Launch Confirmation Dialog) Not Found");
        // TODO - take screen shot.
    }
    
    if ([[[XCUIApplication alloc] init] waitForExistenceWithTimeout:15] == NO) {
        self.appLaunched = TRUE;
        //[self validateDeepLinkDataForRedirectionEnabled:NO];
        [safariApp activate];
        sleep(10);
        NSDictionary* errorDict;
        NSAppleEventDescriptor* returnDescriptor = NULL;
        
        NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                       @"\
                                       tell application \"Safari\" to activate\n\
                                       tell application \"Safari\"\n\
                                       tell current tab of front window\n\
                                       set x to do javascript (\"document.getElementById('info').textContent ;\")\n\
                                       end tell\n\
                                       end tell\n\
                                       return x" ];
        
        returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
        
        NSLog(@"returnDescriptor : %@" , [returnDescriptor stringValue] );
        
        if (returnDescriptor != NULL)
        {
            // successful execution
            if (kAENullEvent != [returnDescriptor descriptorType])
            {
                [self validateDeepLinkData:[returnDescriptor stringValue] IfAppLanuched:NO];
                return;
            }
        }
        NSLog(@"Error : %@" , [errorDict description] );
        XCTFail(@"Test Failed!");
    } else {
        XCTFail("Application not launched");
    }
}
@end
