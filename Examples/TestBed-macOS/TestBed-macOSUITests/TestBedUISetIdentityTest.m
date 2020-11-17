//
//  TestBedUISetIdentityTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/6/20.
//  Copyright © 2020 Branch. All rights reserved.
//


#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

@interface TestBedUISetIdentityTest : TestBedUITest

@end

@implementation TestBedUISetIdentityTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSetIdentityNLogout {
    
    XCTWaiterResult result = [self launchAppAndWaitForSessionStart];
    
    if (result == XCTWaiterResultCompleted) {
        
        [self setIdentity];
        
        XCTAssertTrue([[self serverRequestString] containsString:@"/v1/profile"]);
        
        NSDictionary *serverRequest = [TestBedUIUtils dictionaryFromString:[self serverRequestString]];
        XCTAssertNotNil([serverRequest valueForKey:@"identity_id"]);
        XCTAssertNotNil([serverRequest valueForKey:@"identity"]);
    
        XCTAssertTrue([[self getErrorString] isEqualToString:@"< None >"]);
        
        // TODO : Check for subsequent calls to log events should include the identity specific, sent up as user_data.developer_identity
        
        // Logout
        [self logOut];
        XCTAssertTrue([[self serverRequestString] containsString:@"/v1/logout"]);
        XCTAssertTrue([[self getErrorString] isEqualToString:@"< None >"]);
        
        // TODO :  no subsequent requests should include the developer identity value (“a_user_name”)
    }
    else {
        XCTFail("App Launch / Session Start Failed.");
    }
}

@end
