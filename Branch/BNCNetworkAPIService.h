/**
 @file          BNCNetworkAPIService.m
 @package       Branch-SDK
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCNetworkAPIService : NSObject
- (void) openWithURL:(NSURL*_Nullable)url;
@end

NS_ASSUME_NONNULL_END
