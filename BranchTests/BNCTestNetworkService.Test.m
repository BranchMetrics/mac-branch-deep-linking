/**
 @file          BNCTestNetworkService.Test.m
 @package       BranchTests
 @brief         Test the BNCTestNetworkService.

 @author        Edward Smith
 @date          June 6, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestNetworkService.h"
#import "BNCTestCase.h"
#import "Branch.h"

@interface BNCTestNetworkServiceTest : BNCTestCase
@end

@implementation BNCTestNetworkServiceTest

- (void) testTheTestService {
    BranchConfiguration*config = [BranchConfiguration configurationWithKey:@"key_live_12345"];
    config.networkServiceClass = [BNCTestNetworkService class];
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:config];

    XCTestExpectation*requestExpectation = [self expectationWithDescription:@"testTheTestService-1"];
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        XCTAssertEqualObjects(request.HTTPMethod, @"POST");
        XCTAssertEqualObjects(request.URL.path, @"/v1/logout");
        NSMutableDictionary*truthDictionary = [self mutableDictionaryFromBundleJSONWithKey:@"logoutRequest"];
        NSMutableDictionary*requestDictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
        XCTAssertNotNil(truthDictionary);
        XCTAssertNotNil(requestDictionary);

        [requestExpectation fulfill];
        NSString*responseString = [self stringFromBundleJSONWithKey:@"logoutResponse"];
        return [BNCTestNetworkService operationWithRequest:request response:responseString];
    };

    [branch.networkAPIService clearNetworkQueue];
    XCTestExpectation*expectation = [self expectationWithDescription:@"testTheTestService-2"];
    [branch logoutWithCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
