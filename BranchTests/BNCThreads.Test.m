/**
 @file          BNCThreads.Test.m
 @package       Branch-SDK-Tests
 @brief         Test cases for BNCThreads.

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

@end
