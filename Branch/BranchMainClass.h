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

- (BOOL) isBranchURL:(NSURL*)url;

/**
 @param  url    The URL to open.
 @return BOOL   Returns true if it is a Branch link and an attempt will be made to open the link.
 */
- (BOOL) openURL:(NSURL*_Nullable)url;

/**
 Set the user's identity to an ID used by your system, so that it is identifiable by you elsewhere. Receive
 a completion callback, notifying you whether it succeeded or failed.

 @param   userId    The ID Branch should use to identify this user.
 @param   callback  The callback to be called once the request has completed (success or failure).

 @warning If you use the same ID between users on different sessions / devices, their actions will be merged.
 @warning This request is not removed from the queue upon failure -- it will be retried until it succeeds.
          The callback will only ever be called once, though.
 @warning You should call `logout` before calling `setIdentity:` a second time.
 */
- (void)setIdentity:(NSString*)userId callback:(void (^_Nullable)(NSError*_Nullable))callback;

/**
 Indicates whether or not this user has a custom identity specified for them. Note that this is *independent
 of installs*. If you call setIdentity, this device will have that identity associated with this user until
 `logout` is called. This includes persisting through uninstalls, as we track device id.
 */
- (BOOL)userIsIdentified;

/**
 Clear all of the current user's session items.

 @warning If the request to logout fails, the items will not be cleared.
 */
- (void)logoutWithCallback:(void (^_Nullable)(NSError*_Nullable))callback;

@property (atomic, copy) void (^_Nullable startSessionBlock)(BranchSession*_Nullable session, NSError*_Nullable error);
@property (atomic, strong) NSMutableDictionary* requestMetadataDictionary;
@property (atomic, weak) id<BranchDelegate> delegate;

// Move to category
@property (atomic, strong, readonly) BNCNetworkAPIService* networkAPIService;
@end

NS_ASSUME_NONNULL_END
