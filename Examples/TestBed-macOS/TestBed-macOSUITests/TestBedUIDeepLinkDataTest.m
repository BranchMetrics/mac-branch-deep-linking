//
//  TestBedUIDeepLinkDataTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUITest.h"
#import "TestBedUIUtils.h"


void *kMyKVOContext = (void*)&kMyKVOContext;
XCTestExpectation *expectationForAppLaunch;

@interface TestBedUIDeepLinkDataTest : TestBedUITest

@end

@implementation TestBedUIDeepLinkDataTest

extern void *kMyKVOContext;

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDeepLink {
    
    __block NSDictionary *linkData;
    __block NSString *shortURL;
    
    XCTWaiterResult result = [self launchAppAndWaitForSessionStart];
    
    [XCTContext runActivityNamed:@"CreateShortLink" block:^(id<XCTActivity> activity) {
        if (result == XCTWaiterResultCompleted) {
            
            shortURL = [self createShortLink];
            
            XCTAssertNotNil(shortURL);
            
            XCTAssertTrue([[self serverRequestString] containsString:@"/v1/url"]);
            
            NSDictionary *serverRequestDictionary = [ TestBedUIUtils dictionaryFromString:[self serverRequestString]];
            linkData = [serverRequestDictionary objectForKey:@"data"];
            [self terminateTestBed];
        }
        else {
            XCTFail("App Launch / Session Start Failed.");
            return;
        }
    }];

    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp launch];
    [safariApp activate];
    XCUIElement *element = [safariApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:shortURL];
    [element typeKey:XCUIKeyboardKeyEnter
       modifierFlags:XCUIKeyModifierNone];
    sleep(3.0);
    [[[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ] click];

    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];

    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew
                                       context:kMyKVOContext];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
    

   
    NSMutableString *deepLinkDataString = [[NSMutableString alloc] initWithString:[self dataTextViewString]] ;
    
    XCTAssertTrue([deepLinkDataString isNotEqualTo:@""]);
    
    [deepLinkDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"website" withString:@"\"website\"" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    NSError *error;
    NSDictionary *deepLinkDataDictionary = [NSJSONSerialization JSONObjectWithData: [ deepLinkDataString dataUsingEncoding:NSUTF8StringEncoding ] options:0 error:&error];
    
    for ( NSString* key in linkData){
      XCTAssertNotNil(deepLinkDataDictionary[key]);
      XCTAssertEqualObjects(linkData[key], deepLinkDataDictionary[key]);
    }
}


- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context != kMyKVOContext)
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
                    self.appLaunched = TRUE;
                    break;
                }
            }
    }
}
@end
