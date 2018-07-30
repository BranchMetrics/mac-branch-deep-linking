/**
 @file          BranchMainClass.m
 @package       Branch
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchMainClass.h"
#import "BranchMainClass+Private.h"
#import "BNCLog.h"
#import "BNCNetworkAPIService.h"
#import "BNCSettings.h"
#import "BNCThreads.h"
#import "BNCWireFormat.h"
#import "BNCApplication.h"
#import "BNCNetworkService.h"
#import "BNCURLBlackList.h"
#import "BNCKeyChain.h"
#import "BranchError.h"
#import "NSString+Branch.h"
#import "NSData+Branch.h"
#import "UIViewController+Branch.h"

#pragma mark BranchConfiguration

@interface BranchConfiguration ()
@property (atomic, strong) BNCSettings* settings;
@end

@implementation BranchConfiguration

- (instancetype) init {
    self = [self initWithKey:@""];
    return self;
}

- (instancetype) initWithKey:(NSString *)key {
    self = [super init];
    self.key = [key copy];
    self.useCertificatePinning = YES;
    self.branchAPIServiceURL = @"https://api.branch.io";
    self.networkServiceClass = [BNCNetworkService class];
    self.blackListURLRegex = [NSArray new];
    return self;
}

- (instancetype) copyWithZone:(NSZone*)zone {
    BranchConfiguration* configuration = [[BranchConfiguration alloc] initWithKey:self.key];
    configuration.useCertificatePinning = self.useCertificatePinning;
    configuration.branchAPIServiceURL = [self.branchAPIServiceURL copy];
    configuration.networkServiceClass = self.networkServiceClass;
    configuration.blackListURLRegex = [self.blackListURLRegex copy];
    return configuration;
}

- (BOOL) hasValidKey {
    return ([self.key hasPrefix:@"key_live_"] || [self.key hasPrefix:@"key_test_"]);
}

- (BOOL) isValidConfiguration {
    return (
        self.hasValidKey &&
        self.branchAPIServiceURL.length > 0 &&
        self.networkServiceClass &&
        [self.networkServiceClass conformsToProtocol:@protocol(BNCNetworkServiceProtocol)]
    );
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p key: '%@' %@ %@>",
        NSStringFromClass(self.class),
        (void*) self,
        self.key,
        self.branchAPIServiceURL,
        NSStringFromClass(self.networkServiceClass)
    ];
}

@end

#pragma mark - Branch

@interface Branch ()
- (void) startNewSession;
- (void) endSession;
@property (atomic, strong, readwrite) BNCNetworkAPIService*networkAPIService;
@property (atomic, strong) BranchConfiguration  *configuration;
@property (atomic, strong) BNCSettings          *settings;
@property (atomic, strong) BNCURLBlackList      *URLBlackList;
@property (atomic, strong) BNCURLBlackList      *userURLBlackList;
@property (atomic, strong) NSURL                *delayedOpenURL;
@property (atomic, strong) dispatch_source_t    delayedOpenTimer;
@property (atomic, strong) dispatch_queue_t     workQueue;
@end

#pragma mark - Branch

@implementation Branch

- (instancetype) init {
    self = [super init];
    self.settings = [BNCSettings loadSettings];
    return self;
}

+ (instancetype) sharedInstance {
    static Branch*sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        BNCLogSetDisplayLevel(BNCLogLevelAll);  // eDebug
        sharedInstance = [[Branch alloc] init];
    });
    return sharedInstance;
}

+ (NSString *)bundleIdentifier {
    NSString*_Nullable string =
        [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey];
    return string?:@"";
}

+ (NSString *)kitDisplayVersion {
    NSString*_Nullable string =
        [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return string?:@"";
}

- (Branch*) startWithConfiguration:(BranchConfiguration*)configuration {
    // These function references force the linker to load the categories just in case it forgot.
    BNCForceNSErrorCategoryToLoad();
    BNCForceNSDataCategoryToLoad();
    BNCForceNSStringCategoryToLoad();
    BNCForceUIViewControllerCategoryToLoad();

    if (!configuration.isValidConfiguration) {
        [NSException raise:NSInvalidArgumentException
            format:@"Invalid Branch configuration.\n%@", configuration];
        return self;
    }

    self.configuration = [configuration copy];
    self.configuration.settings = self.settings;
    self.networkAPIService = [[BNCNetworkAPIService alloc] initWithConfiguration:self.configuration];
    self.URLBlackList =
        [[BNCURLBlackList alloc]
            initWithBlackList:self.settings.URLBlackList
            version:self.settings.URLBlackListVersion];
    self.userURLBlackList =
        [[BNCURLBlackList alloc]
            initWithBlackList:self.configuration.blackListURLRegex
            version:0];

#if TARGET_OS_OSX

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidFinishLaunchingNotification:)
        name:NSApplicationDidFinishLaunchingNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationWillBecomeActiveNotification:)
        name:NSApplicationWillBecomeActiveNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidResignActiveNotification:)
        name:NSApplicationDidResignActiveNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidResignActiveNotification:)
        name:NSApplicationWillTerminateNotification
        object:nil];
    [[NSAppleEventManager sharedAppleEventManager]
        setEventHandler:self
        andSelector:@selector(urlAppleEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
        andEventID:kAEGetURL];

#else

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidFinishLaunchingNotification:)
        name:UIApplicationDidFinishLaunchingNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationWillBecomeActiveNotification:)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidResignActiveNotification:)
        name:UIApplicationWillResignActiveNotification
        object:nil];

#endif

    // TODO: This is for debugging only.  Remove it.
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(notificationObserver:)
        name:nil
        object:nil];

    [self openURL:nil];
    return self;
}

- (BOOL) isStarted {
    return (self.configuration && self.networkAPIService && self.settings) ? YES : NO;
}

- (void) dealloc {
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if TARGET_OS_OSX
    [[NSAppleEventManager sharedAppleEventManager]
        removeEventHandlerForEventClass:kInternetEventClass
        andEventID:kAEGetURL];
#endif
}

#pragma mark - Properties

- (void) setLimitFacebookTracking:(BOOL)limitFacebookTracking_ {
    self.settings.limitFacebookTracking = limitFacebookTracking_;
}

- (BOOL) limitFacebookTracking {
    return self.settings.limitFacebookTracking;
}

+ (void) setLoggingEnabled:(BOOL)enabled_ {
    @synchronized(self) {
        BNCLogLevel level = enabled_ ? BNCLogLevelDebug : BNCLogLevelWarning;
        BNCLogSetDisplayLevel(level);
    }
}

+ (BOOL) loggingIsEnabled {
    @synchronized(self) {
        return (BNCLogDisplayLevel() < BNCLogLevelWarning) ? YES : NO;
    }
}

#pragma mark - Application State Changes

#if TARGET_OS_OSX
- (void)urlAppleEvent:(NSAppleEventDescriptor *)event
       withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSAppleEventDescriptor*descriptor = [event paramDescriptorForKeyword:keyDirectObject];
    NSURL *url = [NSURL URLWithString:descriptor.stringValue];
    NSAppleEventDescriptor*source = [event attributeDescriptorForKeyword:keyOriginalAddressAttr];
    NSString*sourceName = source.stringValue;

    NSDictionary*errorDictionary = nil;
    NSAppleEventDescriptor*sourceBundleDescriptor =
        [[[NSAppleScript alloc]
            initWithSource:[NSString stringWithFormat:@"id of app \"%@\"", sourceName]]
                executeAndReturnError:&errorDictionary];
    NSString*sourceBundleID = sourceBundleDescriptor.stringValue;
    
    BNCLogDebugSDK(@"Apple url open event from '%@':%@ URL: %@.", sourceName, sourceBundleID, url);
    [self openURL:url];
}
#endif

- (void)applicationDidFinishLaunchingNotification:(NSNotification*)notification {
    // TODO: Remove this.
    BNCLogMethodName();
    BNCLogDebugSDK(@"userInfo: %@.", notification.userInfo);
}

- (void)applicationWillBecomeActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
    [self startNewSession];
}

- (void)applicationDidResignActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
    [self endSession];
}

- (void) notificationObserver:(NSNotification*)notification {
    // TODO: Remove this.
    //BNCLogDebugSDK(@"Notification '%@'.", notification.name);
}

#pragma mark - Open

- (BOOL) isBranchURL:(NSURL*)url {
    NSString*scheme = [url scheme];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
        return YES; // TODO: For now.

    NSString*appScheme = [BNCApplication currentApplication].defaultURLScheme;
    if (!(scheme && appScheme && [scheme isEqualToString:appScheme]))
        return NO;

    // Check for link click identifier:

    NSString*linkIdentifier = nil;
    NSURLComponents*components = [NSURLComponents componentsWithString:url.absoluteString];
    for (NSURLQueryItem*item in components.queryItems) {
        if ([item.name isEqualToString:@"link_click_id"]) {
            linkIdentifier = item.value;
            break;
        }
    }

    return (linkIdentifier.length > 0) ? YES : NO;
}

- (BOOL) openURL:(NSURL *)url {
    @synchronized(self) {
        if (url != nil && ![self isBranchURL:url]) {
            return NO;
        }
        if (url.absoluteString.length) self.delayedOpenURL = url;
        if (self.delayedOpenTimer) return YES;

        NSTimeInterval kOpenDeadline = 0.750; // The delay may need to be tweaked.

        if (!self.workQueue)
            self.workQueue = dispatch_queue_create("io.branch.sdk.work", DISPATCH_QUEUE_CONCURRENT);

        self.delayedOpenTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.workQueue);
        if (!self.delayedOpenTimer) return YES;

        dispatch_time_t startTime = BNCDispatchTimeFromSeconds(kOpenDeadline);
        dispatch_source_set_timer(
            self.delayedOpenTimer,
            startTime,
            BNCNanoSecondsFromTimeInterval(kOpenDeadline),
            BNCNanoSecondsFromTimeInterval(kOpenDeadline / 10.0)
        );
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.delayedOpenTimer, ^ {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf delayedOpen];
        });
        dispatch_resume(self.delayedOpenTimer);

        return YES;
    }
}

- (BOOL) openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return [self openURL:url];
}

- (BOOL) continueUserActivity:(NSUserActivity *)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return [self openURL:userActivity.webpageURL];
    }
    return NO;
}

- (void) delayedOpen {
    BNCLogMethodName();
    NSURL*openURL = self.delayedOpenURL;
    self.delayedOpenURL = nil;
    if (self.delayedOpenTimer) {
        dispatch_source_cancel(self.delayedOpenTimer);
        self.delayedOpenTimer = nil;
    }
    if (!openURL && self.trackingDisabled) return;

    BNCApplication*application = [BNCApplication currentApplication];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    dictionary[@"device_fingerprint_id"] = BNCWireFormatFromString(self.settings.deviceFingerprintID);
    dictionary[@"identity_id"] = BNCWireFormatFromString(self.settings.identityID);
    dictionary[@"ios_bundle_id"] = BNCWireFormatFromString(application.bundleID);
    dictionary[@"ios_team_id"] = BNCWireFormatFromString(application.teamID);
    dictionary[@"app_version"] = BNCWireFormatFromString(application.displayVersionString);
    dictionary[@"uri_scheme"] = BNCWireFormatFromString(application.defaultURLScheme);
    dictionary[@"facebook_app_link_checked"] = BNCWireFormatFromBool(NO);
    dictionary[@"apple_ad_attribution_checked"] = BNCWireFormatFromBool(NO);

    NSString*blackListPattern = [self.userURLBlackList blackListPatternMatchingURL:openURL];
    if (!blackListPattern) {
        blackListPattern = [self.URLBlackList blackListPatternMatchingURL:openURL];
    }

    if (blackListPattern != nil) {
        dictionary[@"external_intent_uri"] = blackListPattern;
    } else {
        NSString*scheme = openURL.scheme;
        if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
            dictionary[@"universal_link_url"] = openURL.absoluteString;
        } else
        if (scheme.length > 0) {
            dictionary[@"external_intent_uri"] = openURL.absoluteString;
            NSURLComponents*components = [NSURLComponents componentsWithString:openURL.absoluteString];
            for (NSURLQueryItem*item in components.queryItems) {
                if ([item.name isEqualToString:@"link_click_id"]) {
                    dictionary[@"link_identifier"] = item.value;
                    break;
                }
            }
        }
    }

    dictionary[@"limit_facebook_tracking"] = BNCWireFormatFromBool(self.settings.limitFacebookTracking);
    dictionary[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    dictionary[@"previous_update_time"] = BNCWireFormatFromDate(application.previousAppBuildDate);
    dictionary[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    dictionary[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    dictionary[@"update"] = BNCWireFormatFromInteger(application.updateState);
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    NSString*service = (self.settings.identityID.length > 0) ? @"v1/open" : @"v1/install";

    BNCPerformBlockOnMainThreadAsync(^ {
        [self notifyWillStartSessionWithURL:openURL];
    });

    __weak __typeof(self) weakSelf = self;
    [self.networkAPIService postOperationForAPIServiceName:service
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation *operation) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf openResponseWithOperation:operation url:openURL];
        }
    ];
}

- (void) openResponseWithOperation:(BNCNetworkAPIOperation*)operation url:(NSURL*)URL {
    if (operation.error) {
        BNCPerformBlockOnMainThreadAsync(^{
            [self notifyDidStartSession:nil withURL:URL error:operation.error];
        });
        return;
    }

    BranchSession*session = operation.session;
    BranchLinkProperties*linkProperties = [BranchLinkProperties linkPropertiesWithDictionary:session.data];
    session.linkProperties = linkProperties;
    BranchUniversalObject*object = [BranchUniversalObject objectWithDictionary:session.data];
    session.linkContent = object;

    BNCPerformBlockOnMainThreadAsync(^ {
        [self notifyDidStartSession:session withURL:URL error:nil];
    });
    if (session.referringURL) {
        BNCPerformBlockOnMainThreadAsync(^ {
            [self notifyDidOpenURLWithSession:session];
        });
    }
    if (self.settings.URLBlackListLastRefreshDate == nil ||
        [self.settings.URLBlackListLastRefreshDate timeIntervalSinceNow] < (-1.0*24.0*60.0*60.0)) {
        [self.URLBlackList refreshBlackListFromServerWithBranch:self
            completion:^(BNCURLBlackList*blackList, NSError*error) {
                if (error) return;
                self.settings.URLBlackList = blackList.blackList;
                self.settings.URLBlackListVersion = blackList.blackListVersion;
                self.settings.URLBlackListLastRefreshDate = [NSDate date];
            }
        ];
    }
}

- (void) notifyWillStartSessionWithURL:(NSURL*)URL {
    BNCLogAssert([NSThread isMainThread]);
    if ([self.delegate respondsToSelector:@selector(branch:willStartSessionWithURL:)]) {
        [self.delegate branch:self willStartSessionWithURL:URL];
    }
    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchWillStartSessionNotification
        object:self
        userInfo:userInfo];
}

- (void) notifyDidStartSession:(BranchSession*)session withURL:(NSURL*)URL error:(NSError*)error {
    BNCLogAssert([NSThread isMainThread] && (session || error));

    if (session == nil && error == nil) {
        BNCLogError(@"Both session and error are nil!");
        return;
    }

    if (self.sessionStartedBlock)
        self.sessionStartedBlock(session, error);
        
    if (error) {
        if ([self.delegate respondsToSelector:@selector(branch:failedToStartSessionWithURL:error:)])
            [self.delegate branch:self failedToStartSessionWithURL:URL error:error];
    } else {
        if ([self.delegate respondsToSelector:@selector(branch:didStartSession:)])
            [self.delegate branch:self didStartSession:session];
    }

    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    userInfo[BranchSessionKey] = session;
    userInfo[BranchErrorKey] = error;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidStartSessionNotification
        object:self
        userInfo:userInfo];
}

- (void) notifyDidOpenURLWithSession:(BranchSession*)session {
    BNCLogAssert([NSThread isMainThread]);
    if ([self.delegate respondsToSelector:@selector(branch:didOpenURLWithSession:)])
        [self.delegate branch:self didOpenURLWithSession:session];
    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchSessionKey] = session;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidOpenURLWithSessionNotification
        object:self
        userInfo:userInfo];
}

#pragma mark - User Tracking

- (void) setTrackingDisabled:(BOOL)trackingDisabled_ {
    @synchronized(self) {
        if (!!self.settings.trackingDisabled == !!trackingDisabled_) return;
        self.settings.trackingDisabled = trackingDisabled_;
        if (trackingDisabled_) {
            [self.settings clearTrackingInformation];
            [self.networkAPIService clearNetworkQueue];
            //[self.linkCache clear];
        } else {
            // Initialize a Branch session:
            [self startNewSession];
        }
    }
}

- (BOOL) trackingIsDisabled {
    @synchronized(self) {
        return self.settings.trackingDisabled;
    }
}


#pragma mark - User Identity

- (void)setUserIdentity:(NSString*)userID
         completion:(void (^_Nullable)(BranchSession*session, NSError*_Nullable error))completion {
    if (!userID || [self.settings.userIdentityForDeveloper isEqualToString:userID]) {
        if (completion) completion(nil, nil);   // TODO: fix the session.
        return;
    }
    // [self initSessionIfNeededAndNotInProgress];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"identity"] = userID;
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"identity_id"] = self.settings.identityID;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/profile"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation*_Nonnull operation) {
            BNCPerformBlockOnMainThreadAsync(^{
                if (!operation.error) {
                    self.settings.userIdentityForDeveloper = userID;
                    operation.session.userIdentityForDeveloper = userID;
                }
                if (completion) completion(operation.session, operation.error);
            });
        }
    ];
}

- (BOOL)userIdentityIsSet {
    return self.settings.userIdentityForDeveloper != nil;
}

#pragma mark - Logout

- (void)logoutWithCompletion:(void (^_Nullable)(NSError*_Nullable))completion {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"identity_id"] = self.settings.identityID;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/logout"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation * _Nonnull operation) {
            if (!operation.error)
                self.settings.userIdentityForDeveloper = nil;
            BNCPerformBlockOnMainThreadAsync(^{ if (completion) completion(operation.error); });
        }];
}

#pragma mark - Miscellaneous

- (void) startNewSession {
    [self openURL:nil];
}

- (void) endSession {
    [self sendClose];
}

- (void) sendClose {
    if (self.trackingDisabled) return;
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"identity_id"] = self.settings.identityID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/close"
        dictionary:dictionary
        completion:nil];
}

- (NSMutableDictionary*) requestMetadataDictionary {
    return self.settings.requestMetadataDictionary;
}

- (void) setRequestMetadataDictionary:(NSDictionary*_Nullable)dictionary {
    [self.settings.requestMetadataDictionary setDictionary:dictionary];
}

#pragma mark - Links

- (void) branchShortLinkWithContent:(BranchUniversalObject*)content
                     linkProperties:(BranchLinkProperties*)linkProperties
                         completion:(void (^)(NSURL*_Nullable shortURL, NSError*_Nullable error))completion {
    if (content == nil || linkProperties == nil) {
        // TODO: Add localized description.
        NSError*error = [NSError branchErrorWithCode:BNCBadRequestError localizedMessage:@"Bad parameters."];
        if (completion) completion(nil, error);
        return;
    }

    NSMutableDictionary*dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:linkProperties.dictionary];
    dictionary[@"data"] = content.dictionary;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/url"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation * _Nonnull operation) {
            BNCPerformBlockOnMainThreadAsync(^{
                if (operation.error) {
                    if (completion) completion(nil, operation.error);
                    return;
                }
                NSError*error = nil;
                NSURL*url = BNCURLFromWireFormat(operation.session.data[@"url"]);
                if (!url) error = [NSError branchErrorWithCode:BNCBadRequestError];
                if (completion) completion(url, error);
            });
        }];
}

- (NSURL*) branchLongLinkWithContent:(BranchUniversalObject*)content
                      linkProperties:(BranchLinkProperties*)linkProperties {

    NSMutableArray*queryItems = [NSMutableArray new];
    void (^ addItem)(NSString*tag, NSString*value) = ^ (NSString*key, NSString*value) {
        if (value.length && ![value isEqualToString:@"0"]) {
            NSURLQueryItem*item = [NSURLQueryItem queryItemWithName:key value:value];
            [queryItems addObject:item];
        }
    };

    for (NSString *tag in linkProperties.tags) {
        addItem(@"tags", tag);
    }
    addItem(@"alias", linkProperties.alias);
    addItem(@"channel", linkProperties.channel);
    addItem(@"feature", linkProperties.feature);
    addItem(@"stage", linkProperties.stage);
    addItem(@"type", [NSNumber numberWithInteger:linkProperties.linkType].stringValue);
    addItem(@"matchDuration", [NSNumber numberWithInteger:linkProperties.matchDuration].stringValue);
    addItem(@"source", @"mac"); // TODO: Add new sources.

    NSDictionary*dictionary = content.dictionary;
    if (dictionary.count) {
        NSError*error = nil;
        NSData*data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
        if (error) {
            BNCLogError(@"Can't encode content item: %@", error);
        } else {
            NSString*dataString = [data base64EncodedStringWithOptions:0];
            addItem(@"data", dataString);
        }
    }

    NSString*baseURL = nil;
    if (self.settings.linkCreationURL.length)
        baseURL = self.settings.linkCreationURL;
    else
        baseURL = [[NSMutableString alloc] initWithFormat:@"https://bnc.lt/a/%@", self.configuration.key];

    if (self.trackingIsDisabled) {
        NSString *id_string = [NSString stringWithFormat:@"%%24identity_id=%@", self.settings.identityID];
        NSRange range = [baseURL rangeOfString:id_string];
        if (range.location != NSNotFound) {
            NSMutableString*baseURL_ = [baseURL mutableCopy];
            [baseURL_ replaceCharactersInRange:range withString:@""];
            baseURL = baseURL_;
        }
    }

    NSURLComponents*components = [NSURLComponents componentsWithString:baseURL];
    components.queryItems = queryItems;
    NSURL*URL = [components URL];

    return URL;
}

// Used for setting up unit tests mostly.
- (void) clearAllSettings {
    BNCLogDebugSDK(@"[Branch clearAllSettings].");
    if (self.networkAPIService)
        [self.networkAPIService clearNetworkQueue];
    else
        [[[BNCNetworkAPIService alloc] init] clearNetworkQueue];
    [self.settings clearAllSettings];
    NSString*appGroup = [BNCApplication currentApplication].applicationID;
    if (appGroup.length > 0) {
        BNCKeyChain*keyChain = [[BNCKeyChain alloc] initWithSecurityAccessGroup:appGroup];
        NSError*error = [keyChain removeValuesForService:@"BranchKeychainService" key:nil];
        if (error) BNCLogError(@"Can't remove app group '%@' settings: %@.", appGroup, error);
    }
}

@end
