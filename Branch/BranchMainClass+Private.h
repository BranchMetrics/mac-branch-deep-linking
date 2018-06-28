/**
 @file          BranchMainClass+Private.h
 @package       Branch
 @brief         Private definiations for the Branch class.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchMainClass.h"
#import "BNCNetworkAPIService.h"

NS_ASSUME_NONNULL_BEGIN

@interface Branch (Private)
@property (atomic, strong, readonly) BNCNetworkAPIService*networkAPIService;
@property (atomic, strong, readonly) BranchConfiguration*configuration;
+ (void) clearAllSettings;
@end

NS_ASSUME_NONNULL_END
