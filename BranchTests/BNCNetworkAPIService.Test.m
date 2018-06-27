/**
 @file          BNCNetworkAPIService.Test.m
 @package       BranchTests
 @brief         Tests for the BNCNetworkAPIService network class.

 @author        Edward Smith
 @date          June 22, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BranchEvent.h"

@interface BNCNetworkAPIServiceTest : BNCTestCase
@end

@implementation BNCNetworkAPIServiceTest

// These tests are numbered so the execute in order.
// The order increases the complexity of the test.
// This helps debug test failures.

- (void) testRetriesAndTimeout1 {
    // Test the retries for a retry-able operation:
    // Make sure retries happen and then time out.

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block long retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            ++retryCount;
            BNCTestNetworkOperation*operation = [BNCTestNetworkService operationWithRequest:request response:nil];
            operation.HTTPStatusCode = 500;
            return operation;
        };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testRetriesAndTimeout1"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial] completion:
        ^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [expectation fulfill];
        }
    ];

    NSDate*startDate = [NSDate date];
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    NSTimeInterval howLong = - [startDate timeIntervalSinceNow];
    XCTAssertTrue(retryCount > 1 && howLong > 60.0 && howLong < 80.0);
}

- (void) testRetriesAndTimeout2 {
    // Test the retries for a retry-able operation:
    // Make sure retries happen and then succeed.

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block long retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            ++retryCount;
            BNCTestNetworkOperation*operation = nil;
            if (retryCount > 5) {
                operation = [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            } else {
                operation = [BNCTestNetworkService operationWithRequest:request response:nil];
                operation.HTTPStatusCode = 500;
            }
            return operation;
        };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testRetriesAndTimeout2"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial] completion:
        ^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }
    ];

    NSDate*startDate = [NSDate date];
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    NSTimeInterval howLong = - [startDate timeIntervalSinceNow];
    XCTAssertTrue(retryCount > 1 && howLong < 60.0);
}

- (void) testRetriesAndTimeout3 {
    //
    // Fail a non-rety-able operation.
    //

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block long retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            ++retryCount;
            BNCTestNetworkOperation*operation =
                operation = [BNCTestNetworkService operationWithRequest:request response:nil];
            operation.HTTPStatusCode = 409;
            return operation;
        };

    XCTestExpectation *expectation = [self expectationWithDescription:@"testRetriesAndTimeout3"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial] completion:
        ^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [expectation fulfill];
        }
    ];

    NSDate*startDate = [NSDate date];
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    NSTimeInterval howLong = - [startDate timeIntervalSinceNow];
    XCTAssertTrue(retryCount == 1 && howLong < 60.0);
}

- (void) testSaveAndLoadOperations {
    //
    // Save operations to the queue. Quit Branch. Start Branch. See if events replay.
    //

    {
        __block long operationCount = 0;
        BNCTestNetworkService.requestHandler =
            ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
                ++operationCount;
                return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            };

        Branch*branch = [Branch new];
        BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
        configuration.networkServiceClass = BNCTestNetworkService.class;
        [branch startWithConfiguration:configuration];
        branch.networkAPIService.queuePaused = YES;
        [branch.networkAPIService clearNetworkQueue];
        XCTAssertEqual(branch.networkAPIService.queueDepth, 0);
        
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];

        BNCSleepForTimeInterval(1.0);
        XCTAssert(branch.networkAPIService.queueDepth == 3 && operationCount == 0);
    }

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    __block long operationCount = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSaveAndLoadOperations"];
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            ++operationCount;
            if (operationCount == 3) {
                BNCAfterSecondsPerformBlock(0.010, ^{ [expectation fulfill]; });
            }
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        };
    [branch startWithConfiguration:configuration];

    [self waitForExpectationsWithTimeout:3.0 handler:nil];

    // Wait for any extra operation to drain too:
    BNCSleepForTimeInterval(0.5);
    XCTAssertEqual(operationCount, 3);
}

@end
