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

#import "BNCDevice.h"
#import "BNCUserAgentCollector.h"

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

    self.branchAPIServiceURL = @"https://api.branch.io";
    self.networkServiceClass = [BNCNetworkService class];
    self.blackListURLRegex = [NSArray new];
    return self;
}

- (instancetype) copyWithZone:(NSZone*)zone {
    BranchConfiguration* configuration = [[BranchConfiguration alloc] initWithKey:self.key];
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

typedef NS_ENUM(NSInteger, BNCSessionState) {
    BNCSessionStateUninitialized = 0,
    BNCSessionStateInitializing,
    BNCSessionStateInitialized
};

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
@property (atomic, assign) BNCSessionState      sessionState;
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
    // This code does not work with Swift Package Manager or Cocoapods. Adding a quick fix for now
//    NSString*_Nullable string =
//        [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//    return string?:@"";
    return @"1.4.0";
}

- (Branch*) startWithConfiguration:(BranchConfiguration*)configuration {
    
    // This as it relies on startDelayedOpenTimer to beat all the network calls in a race.
    [[BNCUserAgentCollector instance] loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        
    }];
    
    // These function references force the linker to load the categories just in case it forgot.
    BNCForceNSErrorCategoryToLoad();
    BNCForceNSDataCategoryToLoad();
    BNCForceNSStringCategoryToLoad();

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

    [self openURL:nil];
    return self;
}

- (BOOL) isStarted {
    return (self.configuration && self.networkAPIService && self.settings) ? YES : NO;
}

- (void) dealloc {
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSAppleEventManager sharedAppleEventManager]
        removeEventHandlerForEventClass:kInternetEventClass
        andEventID:kAEGetURL];
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

- (void)applicationDidFinishLaunchingNotification:(NSNotification*)notification {
    // TODO: Remove this?
    //BNCLogMethodName();
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

- (void) startDelayedOpenTimer {
    @synchronized(self) {
        if (self.delayedOpenTimer) return;

        NSTimeInterval kOpenDeadline = 0.750; // The delay may need to be tweaked.

        if (!self.workQueue)
            self.workQueue = dispatch_queue_create("io.branch.sdk.work", DISPATCH_QUEUE_CONCURRENT);

        self.delayedOpenTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.workQueue);
        if (!self.delayedOpenTimer) return;

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
    }
}

- (BOOL) openURL:(NSURL *)url {
    @synchronized(self) {
        if (url.absoluteString.length) {
            self.delayedOpenURL = url;
            [self startDelayedOpenTimer];
        } else
        if (self.sessionState == BNCSessionStateUninitialized) {
            self.sessionState = BNCSessionStateInitializing;
            [self startDelayedOpenTimer];
        }
        return [self isBranchURL:url];
    }
}

- (BOOL) openURL:(NSURL *)url
         options:(NSDictionary</*UIApplicationOpenURLOptionsKey*/NSString*, id> *)options {
    return [self openURL:url];
}

- (BOOL) continueUserActivity:(NSUserActivity *)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return [self openURL:userActivity.webpageURL];
    } else {
        NSURL*branchURL = userActivity.userInfo[@"branch"];
        if ([branchURL isKindOfClass:NSURL.class]) {
            [self openURL:branchURL];
            return YES;
        }
    }
    return NO;
}

- (NSURL*) URLWithSchemeSubstitution:(NSURL*)URL {
    BOOL needsSubstitution = NO;
    BNCApplication*application = [BNCApplication currentApplication];
    if (application.defaultURLScheme && [URL.scheme isEqualToString:application.defaultURLScheme]) {
        NSString*urlDomain = URL.host;
        for (NSString*domain in application.associatedDomains) {
            if ([domain hasPrefix:@"applinks:"]) {
                NSString*nakedDomain = [domain substringFromIndex:9];
                if ([urlDomain isEqualToString:nakedDomain]) {
                    needsSubstitution = YES;
                    break;
                }
            }
        }
    }
    if (!needsSubstitution) return URL;
    NSString*newURL =
        [NSString stringWithFormat:@"https%@",
            [URL.absoluteString substringFromIndex:application.defaultURLScheme.length]];
    return [NSURL URLWithString:newURL];
}

- (void) delayedOpen {
    BNCLogMethodName();
    NSURL*openURL = self.delayedOpenURL;
    self.delayedOpenURL = nil;
    if (self.delayedOpenTimer) {
        dispatch_source_cancel(self.delayedOpenTimer);
        self.delayedOpenTimer = nil;
    }
    if (!openURL && self.userTrackingIsDisabled) return;

    self.sessionState = BNCSessionStateInitializing;
    BNCApplication*application = [BNCApplication currentApplication];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    if (self.settings.randomizedBundleToken.length) {
        dictionary[@"randomized_bundle_token"] = BNCWireFormatFromString(self.settings.randomizedBundleToken);
    } else {
        dictionary[@"randomized_bundle_token"] = BNCWireFormatFromString(self.settings.identityID);
    }
    
    if (self.settings.randomizedDeviceToken.length) {
        dictionary[@"randomized_device_token"] = BNCWireFormatFromString(self.settings.randomizedDeviceToken);
    } else {
        dictionary[@"randomized_device_token"] = BNCWireFormatFromString(self.settings.deviceFingerprintID);
    }

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
        openURL = [self URLWithSchemeSubstitution:openURL];
        NSString*scheme = openURL.scheme;
        if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
            dictionary[@"universal_link_url"] = BNCWireFormatFromURL(openURL);
        } else
        if (scheme.length > 0) {
            dictionary[@"external_intent_uri"] = BNCWireFormatFromURL(openURL);
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
    
    NSString*service;
    
    if (self.settings.randomizedBundleToken.length > 0 || self.settings.identityID.length > 0) {
        service = @"v1/open";
    } else {
        service = @"v1/install";
    }
    
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
        self.sessionState = BNCSessionStateUninitialized;
        BNCPerformBlockOnMainThreadAsync(^{
            [self notifyDidStartSession:nil withURL:URL error:operation.error];
        });
        return;
    }
    self.sessionState = BNCSessionStateInitialized;
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

- (void) setUserTrackingDisabled:(BOOL)trackingDisabled_ {
    @synchronized(self) {
        if (!!self.settings.userTrackingDisabled == !!trackingDisabled_) return;
        self.settings.userTrackingDisabled = trackingDisabled_;
        if (trackingDisabled_) {
            [self.settings clearUserIdentifyingInformation];
            [self.networkAPIService clearNetworkQueue];
            //[self.linkCache clear];
        } else {
            // Initialize a Branch session:
            [self startNewSession];
        }
    }
}

- (BOOL) userTrackingIsDisabled {
    @synchronized(self) {
        return self.settings.userTrackingDisabled;
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
    dictionary[@"randomized_device_token"] = self.settings.randomizedDeviceToken;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"randomized_bundle_token"] = self.settings.randomizedBundleToken;
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

- (nullable NSString *)getUserIdentity {
    return self.settings.userIdentityForDeveloper;
}

- (BOOL)userIdentityIsSet {
    return self.settings.userIdentityForDeveloper != nil;
}

#pragma mark - Logout

- (void)logoutWithCompletion:(void (^_Nullable)(NSError*_Nullable))completion {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"randomized_device_token"] = self.settings.randomizedDeviceToken;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"randomized_bundle_token"] = self.settings.randomizedBundleToken;
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
    if (self.userTrackingIsDisabled) return;
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"randomized_bundle_token"] = self.settings.randomizedBundleToken;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"randomized_device_token"] = self.settings.randomizedDeviceToken;
}

- (NSMutableDictionary*_Nonnull) requestMetadataDictionary {
    return self.settings.requestMetadataDictionary;
}

- (void) setRequestMetaDataKey:(NSString *)key Value:(NSString *)value {
    if (!key) {
        return;
    }
    if ([self.settings.requestMetadataDictionary objectForKey:key] && !value) {
        [self.settings.requestMetadataDictionary removeObjectForKey:key];
    }
    else if (value) {
        [self.settings.requestMetadataDictionary setObject:value forKey:key];
    }
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
    
    // Control params must also be at the data level
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data addEntriesFromDictionary:linkProperties.controlParams];
    [data addEntriesFromDictionary:content.dictionary];
    dictionary[@"data"] = data;
    
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

- (void) branchShortUrlWithParams:(nullable NSDictionary *)params andChannel:(nullable NSString *)channel andFeature:(nullable NSString *)feature andTags:(nullable NSArray *)tags andAlias:(nullable NSString *)alias andCallback:(void (^)(NSURL*_Nullable shortURL, NSError*_Nullable error)) callback{
    
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    
    [dictionary addEntriesFromDictionary:params];
    dictionary[@"channel"] =  channel;
    dictionary[@"feature"] =  feature;
    dictionary[@"tags"] =  tags;
    dictionary[@"alias"] =  alias;
    
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/url"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation * _Nonnull operation) {
            BNCPerformBlockOnMainThreadAsync(^{
                if (operation.error) {
                    if (callback) callback(nil, operation.error);
                    return;
                }
                NSError*error = nil;
                NSURL*url = BNCURLFromWireFormat(operation.session.data[@"url"]);
                if (!url) error = [NSError branchErrorWithCode:BNCBadRequestError];
                if (callback) callback(url, error);
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

    if (self.userTrackingIsDisabled) {
        NSString *id_string = [NSString stringWithFormat:@"%%24randomized_bundle_token=%@", self.settings.randomizedBundleToken];
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

// Useful for unit tests mostly.
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
