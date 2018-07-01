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

/// Returns a pointer to the shared Branch instance.
+ (instancetype) sharedInstance;

/// Returns the bundle identifier of the Branch framework.
+ (NSString*) bundleIdentifier;

/// Returns  the display version number of the Branch framework.
+ (NSString*) kitDisplayVersion;

/**
  @param configuration Pass the configuration parameters to start Branch.
  @return Returns a pointer to the receiver.
 */
- (Branch*) startWithConfiguration:(BranchConfiguration*)configuration;

/// Returns true if the Branch SDK has been started.
- (BOOL) isStarted;

/// Returns true if the passed URL is a URL that will be handled by Branch.
- (BOOL) isBranchURL:(NSURL*)url;

/**
 Open a URL with Branch.  This will start a new Branch session.

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

 @warning If the request to logout fails, the session items will not be cleared.
 */
- (void) logoutWithCompletion:(void (^_Nullable)(NSError*_Nullable))completion;

/**
  Generates a Branch short URL that describes the content described in the Branch Universal Object and
  has the passed link properties.

  @param content        The BranchUniversalObject that describes the URL content.
  @param linkProperties The link properties for the short link.
  @param completion     The completion block that receives the short URL or an NSError if the operation fails.
*/
- (void) branchShortLinkWithContent:(BranchUniversalObject*)content
                     linkProperties:(BranchLinkProperties*)linkProperties
                         completion:(void (^)(NSURL*_Nullable shortURL, NSError*_Nullable error))completion;

/**
 Generates a Branch long URL. This method is guaranteed to succeed and is synchronous.

  @param content        The BranchUniversalObject that describes the URL content.
  @param linkProperties The link properties for the short link.
  @return Returns a Branch URL that has the given properties.
*/
- (NSURL*) branchLongLinkWithContent:(BranchUniversalObject*)content
                      linkProperties:(BranchLinkProperties*)linkProperties;

/// Key-value pairs to be included in the metadata on every request.
@property (atomic, strong, null_resettable) NSMutableDictionary* requestMetadataDictionary;

/**
 Disables the Branch SDK from tracking the user. This is useful for GDPR privacy compliance.

 When tracking is disabled, the Branch SDK will clear the Branch defaults of user identifying
 information and prevent Branch from making any Branch network calls that will track the user.

 Note that:

 * Opening Branch deep links with an explicit URL will work.
 * Deferred deep linking will not work.
 * Generating short links will not work and will return long links instead.
 * Sending user tracking events such as `userCompletedAction`, `BranchCommerceEvents`, and
   `BranchEvents` will fail.
 * User rewards and credits will not work.
 * Setting a user identity and logging a user identity out will not work.
*/
@property (atomic, assign, getter=trackingIsDisabled) BOOL trackingDisabled;

/// Enables logging to the console for debugging.  Should be set to `NO` for production apps.
@property (atomic, assign) BOOL enableLogging;

@property (atomic, assign) BOOL limitFacebookTracking;

@property (atomic, weak) id<BranchDelegate> delegate;
@property (atomic, copy) void (^_Nullable startSessionBlock)(BranchSession*_Nullable session, NSError*_Nullable error);
@end

NS_ASSUME_NONNULL_END
