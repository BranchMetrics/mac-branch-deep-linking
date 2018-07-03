/**
 @file          BNCThreads.Test.m
 @package       BranchTests
 @brief         Tests for BNCThreads.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCThreads.h"

@interface BNCThreadsTest : BNCTestCase
@end

@implementation BNCThreadsTest

- (void) testTimeConversion {
    uint64_t nsec = BNCNanoSecondsFromTimeInterval(1.25);
    XCTAssert(nsec == 1250000000ull);

    XCTestExpectation*expectation =
        [self expectationWithDescription:@"BNCAfterSecondsPerformBlockOnMainThread"];
    NSDate*date = [NSDate date];
    BNCAfterSecondsPerformBlockOnMainThread(1.25, ^{
        NSTimeInterval te = [date timeIntervalSinceNow];
        XCTAssertTrue(te + 1.25 < 0.2000);
        [expectation fulfill];
    });
    [self awaitExpectations];
}

- (void) testAsyncQueue {
    XCTestExpectation*expectation =
        [self expectationWithDescription:@"BNCPerformBlockOnMainThreadAsync"];
    BNCPerformBlockOnMainThreadAsync(^{
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    });
    [self awaitExpectations];
}

- (void) testSyncQueue {
    XCTestExpectation*expectation =
        [self expectationWithDescription:@"BNCPerformBlockOnMainThreadSync"];
    XCTAssertTrue([NSThread isMainThread]);
    BNCPerformBlockOnMainThreadSync(^{
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    });
    [self awaitExpectations];
}

- (void) testSleep {
    NSDate*date = [NSDate date];
    BNCSleepForTimeInterval(0.125);
    NSTimeInterval delta = [date timeIntervalSinceNow];
    XCTAssertTrue(delta < -0.125 && delta > -0.200);
}

- (void) testPerforms {
    NSDate*date = [NSDate date];
    XCTestExpectation*expectation =
        [self expectationWithDescription:@"BNCPerformBlockOnMainThreadSync"];
    BNCAfterSecondsPerformBlockOnMainThread(1.0, ^ {
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    });
    [self awaitExpectations];
    NSTimeInterval t = [date timeIntervalSinceNow];
    XCTAssert(t >= -1.5 && t < -1.0);
}

- (void) testBNCPerformBlockAsync {
    XCTestExpectation*expectation = [self expectationWithDescription:@"BNCPerformBlockAsync"];
    BNCPerformBlockAsync( ^ {
        [expectation fulfill];
    });
    [self awaitExpectations];
}

- (void) testBNCAfterSecondsPerformBlock {
    NSDate*date = [NSDate date];
    XCTestExpectation*expectation =
        [self expectationWithDescription:@"BNCAfterSecondsPerformBlock"];
    BNCAfterSecondsPerformBlock(1.0, ^ {
        [expectation fulfill];
    });
    [self awaitExpectations];
    NSTimeInterval t = [date timeIntervalSinceNow];
    XCTAssert(t >= -1.25 && t < -1.0);
}

@end
