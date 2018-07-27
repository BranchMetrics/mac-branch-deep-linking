/**
 @file          BranchOpen.Test.m
 @package       BranchTests
 @brief         Test the Branch Open handling.

 @author        Edward Smith
 @date          June 10, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "Branch.h"
#import "BranchMainClass+Private.h"
#import <stdatomic.h>

@interface BranchOpenTest : BNCTestCase
@end

@implementation BranchOpenTest

- (void) testOpenScheme {
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    [branch clearAllSettings];
    [branch startWithConfiguration:configuration];
    branch.limitFacebookTracking = YES;
    
    // Mock the result. Fix up the expectedParameters for simulator hardware --

    __block _Atomic(NSInteger) callCount = 0;
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        NSInteger count = atomic_fetch_add(&callCount, 1);
        if (count == 0) {
            XCTAssertEqualObjects(request.HTTPMethod, @"POST");
            XCTAssertEqualObjects(request.URL.path, @"/v1/install");
            NSMutableDictionary*truth = [self mutableDictionaryFromBundleJSONWithKey:@"BranchInstallRequestMac"];
            NSMutableDictionary*test = [BNCTestNetworkService mutableDictionaryFromRequest:request];
            for (NSString*key in truth) {
                XCTAssertNotNil(test[key], @"No key '%@'!", key);
                if (test[key] == nil)
                    NSLog(@"No key '%@'!", key);
                test[key] = nil;
            }
            if ([[BNCDevice currentDevice].systemName isEqualToString:@"mac_OS"]) {
                XCTAssert([test[@"mac_id"] hasPrefix:@"mac_"]);
                test[@"mac_id"] = nil;
            } else
            if ([[BNCDevice currentDevice].systemName isEqualToString:@"tv_OS"]) {
                XCTAssert(test[@"idfv"]);
                test[@"idfv"] = nil;
                test[@"idfa"] = nil;
            }
            XCTAssert(test.count == 0, @"Found keys: %@.", test);
            NSString*response = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
            XCTAssertNotNil(response);
            return [BNCTestNetworkService operationWithRequest:request response:response];
        } else {
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        }
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testOpenScheme"];
    branch.sessionStartedBlock = ^ (BranchSession * _Nullable session, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(session);
        NSString*result = session.description;
        XCTAssert([result hasPrefix:@"<BranchSession 0x"]);
        [expectation fulfill];
    };
    
    [branch.networkAPIService clearNetworkQueue];
    [branch openURL:[NSURL URLWithString:@"testbed-mac://open?link_click_id=348527481794276288"]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testOpenHTTP {
    NSString*const kTestURL = @"https://testbed-mac.app.link/ODYeswaVWM";
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    [branch clearAllSettings];
    [branch startWithConfiguration:configuration];
    branch.limitFacebookTracking = YES;

    // Mock the result. Fix up the expectedParameters for simulator hardware --

    __block BOOL foundInstallRequest = NO;
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        if ([request.URL.path isEqualToString:@"/v1/install"]) {
            foundInstallRequest = YES;
            XCTAssertEqualObjects(request.HTTPMethod, @"POST");
            NSMutableDictionary*truth = [self mutableDictionaryFromBundleJSONWithKey:@"BranchInstallRequestMac"];
            truth[@"external_intent_uri"] = nil;
            truth[@"link_identifier"] = nil;
            truth[@"universal_link_url"] = kTestURL;
            NSMutableDictionary*test = [BNCTestNetworkService mutableDictionaryFromRequest:request];
            for (NSString*key in truth) {
                XCTAssertNotNil(test[key], @"No key '%@'!", key);
                if (test[key] == nil)
                    NSLog(@"No key '%@'!", key);
                test[key] = nil;
            }
            if ([[BNCDevice currentDevice].systemName isEqualToString:@"mac_OS"]) {
                XCTAssert([test[@"mac_id"] hasPrefix:@"mac_"]);
                test[@"mac_id"] = nil;
            } else
            if ([[BNCDevice currentDevice].systemName isEqualToString:@"tv_OS"]) {
                XCTAssert(test[@"idfv"]);
                test[@"idfv"] = nil;
                test[@"idfa"] = nil;
            }
            XCTAssert(test.count == 0, @"Found keys: %@.", test);
            NSString*response = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
            XCTAssertNotNil(response);
            return [BNCTestNetworkService operationWithRequest:request response:response];
        } else {
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        }
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testOpenHTTP"];
    branch.sessionStartedBlock = ^ (BranchSession * _Nullable session, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(session);
        NSString*result = session.description;
        XCTAssert([result hasPrefix:@"<BranchSession 0x"]);
        [expectation fulfill];
    };

    [branch openURL:[NSURL URLWithString:kTestURL]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(foundInstallRequest);
}

@end
