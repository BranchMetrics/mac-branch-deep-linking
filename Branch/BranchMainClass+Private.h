/**
 @file          BranchMainClass+Private.h
 @package       Branch
 @brief         Private definitions for the Branch class.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Branch/BranchMainClass.h>
@class BNCNetworkAPIService, BNCSettings;

NS_ASSUME_NONNULL_BEGIN

@interface Branch (Private)
@property (atomic, strong, readonly) BNCNetworkAPIService*_Nullable networkAPIService;
@property (atomic, strong, readonly) BranchConfiguration*_Nullable configuration;
+ (void) clearAllSettings;
@end

@interface BranchConfiguration (Private)
@property (atomic, strong, readonly) BNCSettings* settings;
@end

NS_ASSUME_NONNULL_END
