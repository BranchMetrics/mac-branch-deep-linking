//
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

    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        XCTAssert([request.HTTPMethod isEqualToString:@"POST"]);
        XCTAssert([request.URL.absoluteString containsString:@"logout"]);
        NSMutableDictionary*truthDictionary = [self mutableDictionaryFromBundleJSONWithKey:@"logoutRequest"];
        NSMutableDictionary*requestDictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
        XCTAssertNotNil(truthDictionary);
        XCTAssertNotNil(requestDictionary);

        NSString*responseString = [self stringFromBundleJSONWithKey:@"logoutResponse"];
        return [BNCTestNetworkService operationWithRequest:request response:responseString];
    };

    XCTestExpectation*expectation = [self expectationWithDescription:@"testTheTestService"];
    [branch logoutWithCallback:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
