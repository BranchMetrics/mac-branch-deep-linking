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

@interface BranchOpenTest : BNCTestCase
@end

@implementation BranchOpenTest

- (void) testOpenScheme {
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:configuration];
    branch.limitFacebookTracking = YES;
    
    // Mock the result. Fix up the expectedParameters for simulator hardware --

    __block NSInteger callCount = 0;
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        ++callCount;
        if (callCount == 1) {
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
            XCTAssert(test.count == 0, @"Found keys: %@.", test);
            NSString*response = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
            XCTAssertNotNil(response);
            return [BNCTestNetworkService operationWithRequest:request response:response];
        } else {
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        }
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testOpenScheme"];
    branch.startSessionBlock = ^ (BranchSession * _Nullable session, NSError * _Nullable error) {
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

@end
