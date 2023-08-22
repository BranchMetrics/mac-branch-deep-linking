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
    BranchConfiguration*config = [[BranchConfiguration alloc] initWithKey:@"key_live_12345"];
    config.networkServiceClass = [BNCTestNetworkService class];
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:config];

    XCTestExpectation*requestExpectation = [self expectationWithDescription:@"testTheTestService-1"];
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        XCTAssertEqualObjects(request.HTTPMethod, @"POST");
        XCTAssertEqualObjects(request.URL.path, @"/v1/install");
        NSMutableDictionary*truthDictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchInstallRequestMac"];
        NSMutableDictionary*requestDictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
        XCTAssertNotNil(truthDictionary);
        XCTAssertNotNil(requestDictionary);

        [requestExpectation fulfill];
        NSString*responseString = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
        return [BNCTestNetworkService operationWithRequest:request response:responseString];
    };
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
