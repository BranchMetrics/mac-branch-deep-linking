/**
 @file          BNCThreads.h
 @package       Branch-SDK
 @brief         Utilities for working with threads, queues, and blocks.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

///@group Blocks and Threads
#pragma mark - Blocks and Threads

static inline uint64_t BNCNanoSecondsFromTimeInterval(NSTimeInterval interval) {
    return interval * ((NSTimeInterval) NSEC_PER_SEC);
}

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds) {
	return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlockOnMainThread(NSTimeInterval seconds, dispatch_block_t block) {
	dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

static inline void BNCAfterSecondsPerformBlock(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    dispatch_after(BNCDispatchTimeFromSeconds(seconds), queue, block);
}

static inline void BNCPerformBlockOnMainThreadAsync(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline void BNCPerformBlockAsync(dispatch_block_t block) {
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    dispatch_async(queue, block);
}

static inline void BNCPerformBlockOnMainThreadSync(dispatch_block_t block) {
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

static inline void BNCSleepForTimeInterval(NSTimeInterval seconds) {
    double secPart = trunc(seconds);
    double nanoPart = trunc((seconds - secPart) * ((double)NSEC_PER_SEC));
    struct timespec sleepTime;
    sleepTime.tv_sec = (__typeof(sleepTime.tv_sec)) secPart;
    sleepTime.tv_nsec = (__typeof(sleepTime.tv_nsec)) nanoPart;
    nanosleep(&sleepTime, NULL);
}

NS_ASSUME_NONNULL_END
