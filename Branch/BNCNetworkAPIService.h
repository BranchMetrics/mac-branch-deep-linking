/**
 @file          BNCNetworkAPIService.m
 @package       Branch-SDK
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
@class BranchConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface BNCNetworkAPIService : NSObject
- (instancetype) initWithConfiguration:(BranchConfiguration*)configuration;
- (void) openURL:(NSURL*_Nullable)url;
- (void) sendClose;
@end

NS_ASSUME_NONNULL_END
