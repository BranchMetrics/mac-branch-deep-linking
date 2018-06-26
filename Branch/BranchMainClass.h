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
#import "BranchSession.h"
@class BNCSettings;

NS_ASSUME_NONNULL_BEGIN

#pragma mark BranchConfiguration

@interface BranchConfiguration : NSObject <NSCopying>
- (instancetype) initWithKey:(NSString*)key NS_DESIGNATED_INITIALIZER;
+ (BranchConfiguration*) configurationWithKey:(NSString*)key;

@property (atomic, strong) NSString*    key;
@property (atomic, assign) BOOL         useCertificatePinning;
@property (atomic, copy)   NSString*    branchAPIServiceURL;
@property (atomic, assign) Class        networkServiceClass;
@property (atomic, strong) NSArray<NSString*>* blackListURLRegex;
@property (atomic, strong) BNCSettings* settings;
@end

#pragma mark - Branch

@interface Branch : NSObject
+ (instancetype) sharedInstance;
+ (NSString*) bundleIdentifier;
+ (NSString*) kitDisplayVersion;

- (Branch*) startWithConfiguration:(BranchConfiguration*)configuration;
- (BOOL) isStarted;
- (BOOL) isBranchURL:(NSURL*)url;

/**
 @param  url    The URL to open.
 @return BOOL   Returns true if it is a Branch link and an attempt will be made to open the link.
 */
- (BOOL) openURL:(NSURL*_Nullable)url;

/**
 Set the user's identity to an ID used by your system, so that it is identifiable by you elsewhere. Receive
 a completion callback, notifying you whether it succeeded or failed.

 @param   userId      The ID Branch should use to identify this user.
 @param   completion  The callback to be called once the request has completed (success or failure).

 @warning If you use the same ID between users on different sessions / devices, their actions will be merged.
 @warning This request is not removed from the queue upon failure -- it will be retried until it succeeds.
          The callback will only ever be called once, though.
 @warning You should call `logout` before calling `setIdentity:` a second time.
 */
- (void)setUserIdentity:(NSString*)userId
         completion:(void (^_Nullable)(BranchSession*_Nullable session, NSError*_Nullable error))completion;

/**
 Indicates whether or not this user has a custom identity specified for them. Note that this is *independent
 of installs*. If you call setIdentity, this device will have that identity associated with this user until
 `logout` is called. This includes persisting through uninstalls, as we track device id.
 */
- (BOOL)userIdentityIsSet;

/**
 Clear all of the current user's session items.

 @warning If the request to logout fails, the items will not be cleared.
 */
- (void) logoutWithCompletion:(void (^_Nullable)(NSError*_Nullable))completion;

- (void) branchShortLinkWithContent:(BranchUniversalObject*)content
                     linkProperties:(BranchLinkProperties*)linkProperties
                         completion:(void (^)(NSURL*_Nullable shortURL, NSError*_Nullable error))completion;

- (NSURL*) branchLongLinkWithContent:(BranchUniversalObject*)content
                      linkProperties:(BranchLinkProperties*)linkProperties;

@property (atomic, strong) NSMutableDictionary* requestMetadataDictionary;
@property (atomic, assign, getter=trackingIsDisabled) BOOL trackingDisabled;
@property (atomic, assign) BOOL limitFacebookTracking;
@property (atomic, weak) id<BranchDelegate> delegate;
@property (atomic, copy) void (^_Nullable startSessionBlock)(BranchSession*_Nullable session, NSError*_Nullable error);
@end

NS_ASSUME_NONNULL_END
