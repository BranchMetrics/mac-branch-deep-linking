//
//  TestBedUIV2EventTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/6/20.
//  Copyright © 2020 Branch. All rights reserved.
//


#import "TestBedUITest.h"
#import "TestBedUIUtils.h"
#import <Branch/BranchEvent.h>

@interface TestBedUIV2EventTest : TestBedUITest

@end

@implementation TestBedUIV2EventTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSendV2Events {
    
    XCTWaiterResult result = [self launchAppAndWaitForSessionStart];

    if (result == XCTWaiterResultCompleted) {
        
        NSArray *events = [BranchEvent standardEvents];
        
        for (NSString *eventName in events) {
            
            [self logEvent:eventName];
            XCTAssertTrue([[self serverRequestString] containsString:@"/v2/event/standard"]);
            XCTAssertTrue([[self getErrorString] isEqualToString:@"< None >"]);
        }
        
        [self logEvent:@"Custom Event"];
        XCTAssertTrue([[self serverRequestString] containsString:@"/v2/event/custom"]);
        XCTAssertTrue([[self getErrorString] isEqualToString:@"< None >"]);

    } else {
        XCTFail("App Launch / Session Start Failed.");
    }
}

@end
