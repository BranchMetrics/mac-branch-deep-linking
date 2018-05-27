/**
 @file          BranchMainClass.h
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchDelegate.h"
@class BranchSession, BNCNetworkAPIService;

NS_ASSUME_NONNULL_BEGIN

@interface BranchConfiguration : NSObject
@property (atomic, strong) NSString*_Nullable key;
@end

@interface Branch : NSObject
+ (instancetype) sharedInstance;
+ (NSString*) bundleIdentifier;
+ (NSString*) kitDisplayVersion;

- (void) startWithConfiguration:(BranchConfiguration*)configuration;

/// Returns YES if it's a Branch URL.
- (BOOL) openURL:(NSURL*)url;
- (void) startNewSession;
- (void) endSession;

@property (atomic, copy) void (^_Nullable startSessionBlock)(BranchSession*_Nullable session, NSError*_Nullable error);
@property (atomic, strong) NSMutableDictionary* requestMetadataDictionary;
@property (atomic, weak) id<BranchDelegate> delegate;

// Move to category
@property (atomic, strong, readonly) BNCNetworkAPIService* networkService;
@end

NS_ASSUME_NONNULL_END
