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
#import <stdatomic.h> // import not available in Xcode 7

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
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block _Atomic(long) retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            atomic_fetch_add(&retryCount, 1);
            BNCTestNetworkOperation*operation = [BNCTestNetworkService operationWithRequest:request response:nil];
            operation.HTTPStatusCode = 500;
            BNCSleepForTimeInterval(15.0);
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
    long count = atomic_load(&retryCount);
    XCTAssertTrue(count > 1 && howLong > 60.0 && howLong < 80.0);
}

- (void) testRetriesAndTimeout2 {
    // Test the retries for a retry-able operation:
    // Make sure retries happen and then succeed.

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block _Atomic(long) retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            atomic_fetch_add(&retryCount, 1);
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
    long count = atomic_load(&retryCount);
    XCTAssertTrue(count > 1 && howLong < 60.0);
}

- (void) testRetriesAndTimeout3 {
    //
    // Fail a non-rety-able operation.
    //

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block _Atomic(long) retryCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            atomic_fetch_add(&retryCount, 1);
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
    long count = atomic_load(&retryCount);
    XCTAssertEqual(count, 1);
    XCTAssertLessThan(howLong, 60.0);
}

- (void) testSaveAndLoadOperations {
    //
    // Save operations to the queue. Quit Branch. Start Branch. See if events replay.
    //
    {
        __block _Atomic(long) operationCount1 = 0;
        BNCTestNetworkService.requestHandler =
            ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
                atomic_fetch_add(&operationCount1, 1);
                return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            };

        Branch*branch = [Branch new];
        [branch clearAllSettings];
        BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
        configuration.networkServiceClass = BNCTestNetworkService.class;
        [branch startWithConfiguration:configuration];
        branch.networkAPIService.queuePaused = YES;
        XCTAssertEqual(branch.networkAPIService.queueDepth, 0);
        
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];
        [branch logEvent:[BranchEvent standardEvent:BranchStandardEventCompleteTutorial]];

        BNCSleepForTimeInterval(1.0);
        long count = atomic_load(&operationCount1);
        XCTAssertEqual(branch.networkAPIService.queueDepth, 4);
        XCTAssertEqual(count, 0);
    }

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    __block _Atomic(long) operationCount2 = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSaveAndLoadOperations"];
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            long count = atomic_fetch_add(&operationCount2, 1);
            if (count == 4) {
                BNCAfterSecondsPerformBlock(1.00, ^{ [expectation fulfill]; });
            }
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        };
    [branch startWithConfiguration:configuration];
    [self waitForExpectationsWithTimeout:120.0 handler:nil];
    long count = atomic_load(&operationCount2);
    XCTAssertEqual(count, 6);
}

- (void) testRequestMetadata {
    Branch*branch = [Branch new];
    [branch clearAllSettings];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    __block long requestCount = 0;
    __block BOOL foundMetadata = YES;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            @synchronized(self) {
                if ([request.HTTPMethod isEqualToString:@"POST"]) {
                    requestCount++;
                    NSLog(@"WTF: %ld request: %@.", requestCount, request.URL.path);
                    NSDictionary*metadata = @{
                        @"key1": @"value1",
                        @"key2": @"value2",
                        @"key3": @"value3"
                    };
                    NSMutableDictionary*dictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                    NSLog(@"%@", dictionary);
                    if (![dictionary[@"metadata"] isEqualToDictionary:metadata])
                        foundMetadata = NO;
                }
                return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            }
        };

    // Set metadata and start branch:
    branch.requestMetadataDictionary = (id) @{
        @"key1": @"value1",
        @"key2": @"value2"
    };
    branch.requestMetadataDictionary[@"key3"] = @"value3";
    [branch startWithConfiguration:configuration];

    BNCSleepForTimeInterval(1.0); // TODO: Fix! Make sure open happens first before event.
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRequestMetadata"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventSearch]
        completion: ^ (NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }
    ];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertEqual(foundMetadata, YES);
    XCTAssertEqual(requestCount, 2);
}

- (void) testRequestMetadataKeyValue{
    Branch*branch = [Branch new];
    [branch clearAllSettings];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    __block long requestCount = 0;
    __block BOOL foundMetadata = YES;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            @synchronized(self) {
                if ([request.HTTPMethod isEqualToString:@"POST"]) {
                    requestCount++;
                    NSLog(@"WTF: %ld request: %@.", requestCount, request.URL.path);
                    NSDictionary*metadata = @{
                        @"key1": @"value1",
                        @"key2": @"value2",
                        @"key3": @"value3"
                    };
                    NSMutableDictionary*dictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                    NSLog(@"%@", dictionary);
                    if (![dictionary[@"metadata"] isEqualToDictionary:metadata])
                        foundMetadata = NO;
                }
                return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            }
        };

    // Set metadata and start branch:
    
    [branch setRequestMetaDataKey:@"key1" Value:@"value1"];
    [branch setRequestMetaDataKey:@"key2" Value:@"value2"];
    [branch setRequestMetaDataKey:@"key3" Value:@"value3"];
    
    [branch startWithConfiguration:configuration];

    BNCSleepForTimeInterval(1.0); // TODO: Fix! Make sure open happens first before event.
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRequestMetadata"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventSearch]
        completion: ^ (NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }
    ];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertEqual(foundMetadata, YES);
    XCTAssertEqual(requestCount, 2);
}

- (void) testInstrumentation {
    Branch*branch = [Branch new];
    [branch clearAllSettings];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    __block long requestCount = 0;
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            @synchronized(self) {
                requestCount++;
                NSMutableDictionary*dictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                NSLog(@"WTF: %ld request: %@.", requestCount, request.URL.path);
                NSLog(@"%@", dictionary);
                if ([request.URL.path isEqualToString:@"/v2/event/standard"]) {
                    NSString*brtt = dictionary[@"instrumentation"][@"/v1/install-brtt"];
                    XCTAssertGreaterThan([brtt integerValue], 1);
                }
                return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            }
        };

    [branch startWithConfiguration:configuration];
    BNCSleepForTimeInterval(3.0); // TODO: Fix! Make sure open happens first before event.
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInstrumentation"];
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventSearch]
        completion: ^ (NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }
    ];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
