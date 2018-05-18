/**
 @file          BranchClass.h
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchConfiguration : NSObject
@property (atomic, strong) NSString*_Nullable key;
@property (nonatomic, copy) void (^_Nullable deeplinkCallback)(void);
@end

@interface Branch : NSObject
+ (instancetype) sharedInstance;
+ (NSString*) bundleIdentifier;
+ (NSString*) kitDisplayVersion;

- (void) startWithConfiguration:(BranchConfiguration*)configuration;

- (void) startNewSession;
- (void) endSession;

/// Returns YES if it's liekly to be handled be Branch.
- (BOOL) openURL:(NSURL*)url;

//@property (nonatomic, weak) id<BranchDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
