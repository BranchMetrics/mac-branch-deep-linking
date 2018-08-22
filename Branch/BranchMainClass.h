/**
 @file          BranchMainClass.h
 @package       Branch
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchDelegate.h"
#import "BranchSession.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark BranchConfiguration

/**
 Use a `BranchConfiguration` object to configure Branch for your app when you start Branch.
*/
@interface BranchConfiguration : NSObject <NSCopying>

- (instancetype) init NS_UNAVAILABLE;

/**
 @param key Your Branch key.

 @return Returns an initialized `BranchConfiguration` object.
*/
- (instancetype) initWithKey:(NSString*)key NS_DESIGNATED_INITIALIZER;

/** Your Branch key. */
@property (atomic, strong) NSString*key;

/** Use certificate pinning for extra security. The default is to use certificate pinning. */
@property (atomic, assign) BOOL useCertificatePinning;

/** The URL to the Branch API servers. */
@property (atomic, copy)   NSString*branchAPIServiceURL;

/**
    This is `Class` for the network service. If you want to use your own underlying network service,
    set the `Class` of the service here before you start Branch. The class most conform to the
    `BranchNetworkServiceProtocol` defined here:

    @see `Branch/BranchNetworkServiceProtocol.h`

    You probably don't need to do this.
*/
@property (atomic, assign) Class networkServiceClass;

/**
  Sets an array of regex patterns that match URLs for Branch to ignore.

 Set this property to prevent URLs containing sensitive data such as oauth tokens,
 passwords, login credentials, and other URLs from being transmitted to Branch.

 The Branch SDK already ignores login URLs for Facebook, Twitter, Google, and many oauth
 security URLs, so it's usually unnecessary to set this parameter yourself.

 Set this parameter with any additional URLs that should be ignored by Branch.

 These are ICU standard regular expressions.
*/
@property (atomic, strong) NSArray<NSString*>*blackListURLRegex;
@end

#pragma mark - Branch

/**
  The `Branch` class is the main class for interacting with Branch services.
*/
@interface Branch : NSObject

/** Returns a pointer to the shared Branch instance. */
@property (class, readonly, strong) Branch *sharedInstance;

/** Returns the bundle identifier of the Branch framework. */
@property (class, readonly, strong) NSString *bundleIdentifier;

/** Returns  the display version number of the Branch framework. */
@property (class, readonly, strong) NSString *kitDisplayVersion;

/**
  @param configuration Pass the configuration parameters for your app.

  @return Returns a pointer to the receiver.
 */
- (Branch*) startWithConfiguration:(BranchConfiguration*)configuration;

/** Returns true if the Branch SDK has been started. */
@property (atomic, assign, readonly) BOOL isStarted;

/** Returns true if the passed URL is a URL that will be handled by Branch. */
- (BOOL) isBranchURL:(NSURL*)url;

/**
 Open a URL with Branch.  This will start a new Branch session.

 @param  url    The URL to open.

 @return BOOL   Returns true if it is a Branch link and an attempt will be made to open the link.
 */
- (BOOL) openURL:(NSURL*_Nullable)url;

/**
 Open a URL with Branch.

 This should be called from an iOS or tvOS application delegate method
 `- (BOOL) openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;`.

 @param url     The URL passed by the OS.
 @param options The options passed by the OS.

 @return Returns `true` if Branch can handle this URL, `false` otherwise.
*/
- (BOOL) openURL:(NSURL *)url options:(NSDictionary</*UIApplicationOpenURLOptionsKey*/NSString*, id> *)options;

/**
 Opens a URL that was passed in an app continuation.

 This should be called from your application's delegate method
 ```
- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void (^)(NSArray *))restorationHandler
```

so that Branch can handle the passed URL.

 @param userActivity The `NSUserActivity` that was passed to your application.
 @return Returns `true` if Branch can handle the passed URL, `false` otherwise.
*/
- (BOOL) continueUserActivity:(NSUserActivity *)userActivity;

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
 `logoutWithCompletion` is called. This includes persisting through uninstalls, as we track device id.
*/
@property (atomic, assign, readonly) BOOL userIdentityIsSet;

/**
 Clear all of the current user's session items.

 @param completion An optional completion block that is called by Branch with the success or failure
                   of the logout.

 @warning If the request to logout fails, the session items will not be cleared.
 */
- (void) logoutWithCompletion:(void (^_Nullable)(NSError*_Nullable error))completion;

/**
 Generates a Branch short URL that describes the content described in the Branch Universal Object and
 has the passed link properties.

 A short link will not be able to be generated if networking is not available. In that case create a long
 link, which is guaranteed to succeed, but can be very long.

 @param content        The BranchUniversalObject that describes the URL content.
 @param linkProperties The link properties for the short link.
 @param completion     The completion block that receives the short URL or an NSError if the operation
                       fails.
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

/** Key-value pairs to be included in the metadata on every request. */
- (NSMutableDictionary*) requestMetadataDictionary;
- (void) setRequestMetadataDictionary:(NSDictionary*_Nullable)dictionary;

/**
 Disables the Branch SDK from tracking the user. This is useful for GDPR privacy compliance.

 When tracking is disabled, the Branch SDK will clear the Branch defaults of user identifying
 information and prevent Branch from making any Branch network calls that will track the user.

 Note that:

 + Opening Branch deep links with an explicit URL will work.
 + Deferred deep linking will not work.
 + Generating short links will not work and will return long links instead.
 + Sending user tracking events such as `userCompletedAction`, `BranchCommerceEvents`, and
   `BranchEvents` will fail.
 + User rewards and credits will not work.
 + Setting a user identity and logging a user identity out will not work.
*/
@property (atomic, assign, getter=trackingIsDisabled) BOOL trackingDisabled;

/** Enables logging to the console for debugging.  Should be set to `NO` for production apps. */
@property (atomic, assign, getter=loggingIsEnabled, class) BOOL loggingEnabled;

/**
 If you are tracking users through Facebook installs and events well as with Branch, setting this property
 to true limits the amount of user data that is synchronized with Facebook for this user.
*/
@property (atomic, assign) BOOL limitFacebookTracking;

/**
 Sets the `BranchDelegate` object if you want to track Branch events with delegate methods.
 @see <Branch/BranchDelegate.h>
*/
@property (atomic, weak) id<BranchDelegate> delegate;

/**
 Set the `sessionStartedBlock` with a call back block if you want to be notified of start of Branch sessions
 though a block call back.
*/
@property (atomic, copy) void (^_Nullable sessionStartedBlock)(BranchSession*_Nullable session,
                                                               NSError*_Nullable error);
@end

NS_ASSUME_NONNULL_END
