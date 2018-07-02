/**
 @file          BranchDelegate.h
 @package       Branch
 @brief         Branch delegate protocol and notifications.

 @author        Edward Smith
 @date          June 30, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

// TODO: Add documentation

#import "BranchHeader.h"
@class Branch, BranchSession;

NS_ASSUME_NONNULL_BEGIN

#pragma mark BranchDelegate Protocol

@protocol BranchDelegate <NSObject>

@optional
- (void) branch:(Branch*)branch willStartSessionWithURL:(NSURL*_Nullable)url;
- (void) branch:(Branch*)branch didStartSession:(BranchSession*)session;
- (void) branch:(Branch*)branch failedToStartSessionWithURL:(NSURL*_Nullable)url
                                                      error:(NSError*_Nullable)error;
- (void) branch:(Branch*)branch didOpenURLWithSession:(BranchSession*)session;
@end

#pragma mark - Branch Notifications and Keys

FOUNDATION_EXPORT NSString*const BranchWillStartSessionNotification;
FOUNDATION_EXPORT NSString*const BranchDidStartSessionNotification;
FOUNDATION_EXPORT NSString*const BranchDidOpenURLWithSessionNotification;

FOUNDATION_EXPORT NSString*const BranchURLKey;
FOUNDATION_EXPORT NSString*const BranchSessionKey;
FOUNDATION_EXPORT NSString*const BranchErrorKey;

NS_ASSUME_NONNULL_END
