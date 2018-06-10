/**
 @file          BranchMainClass.m
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchMainClass.h"
#import "BNCLog.h"
#import "BNCNetworkAPIService.h"
#import "BNCSettings.h"
#import "BNCThreads.h"
#import "BNCWireFormat.h"
#import "BNCApplication.h"
#import "BNCNetworkService.h"
#import "BNCURLBlackList.h"
#import "BranchError.h"
#import "NSString+Branch.h"
#import "NSData+Branch.h"

#pragma mark BranchConfiguration

@implementation BranchConfiguration

- (instancetype) init {
    self = [self initWithKey:@""];
    return self;
}
- (instancetype) initWithKey:(NSString *)key {
    self = [super init];
    self.key = [key copy];
    if (!self.hasValidKey) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid Branch key '%@'.", key];
    }
    self.useCertificatePinning = NO;
    self.branchAPIServerURL = @"https://api.branch.io";
    self.networkServiceClass = [BNCNetworkService class];
    return self;
}

+ (BranchConfiguration*) configurationWithKey:(NSString*)key {
    BranchConfiguration* configuration = [[BranchConfiguration alloc] initWithKey:key];
    return configuration;
}

- (instancetype) copyWithZone:(NSZone*)zone {
    BranchConfiguration* configuration = [[BranchConfiguration alloc] initWithKey:self.key];
    configuration.useCertificatePinning = self.useCertificatePinning;
    configuration.branchAPIServerURL = [self.branchAPIServerURL copy];
    configuration.networkServiceClass = self.networkServiceClass;
    return configuration;
}

- (BOOL) hasValidKey {
    return ([self.key hasPrefix:@"key_live_"] || [self.key hasPrefix:@"key_test_"]);
}

- (BOOL) isValidConfiguration {
    return (
        self.hasValidKey &&
        self.branchAPIServerURL.length > 0 &&
        [self.networkServiceClass conformsToProtocol:@protocol(BNCNetworkServiceProtocol)]
    );
}

@end

#pragma mark - Branch

@interface Branch ()
- (void) startNewSession;
- (void) endSession;
@property (readwrite) BNCNetworkAPIService      *networkAPIService;
@property (atomic, strong) BranchConfiguration  *configuration;
@property (atomic, strong) BNCSettings          *settings;
@property (atomic, strong) BNCURLBlackList      *URLBlackList;
@property (atomic, strong) NSURL                *delayedOpenURL;
@property (atomic, strong) dispatch_source_t    delayedOpenTimer;
@property (atomic, strong) dispatch_queue_t     workQueue;
@end

@implementation Branch

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

- (void) startWithConfiguration:(BranchConfiguration*)configuration {
    // These function references force the linker to load the categories just in case it forgot.
    BNCForceNSErrorCategoryToLoad();
    BNCForceNSDataCategoryToLoad();
    BNCForceNSStringCategoryToLoad();

    if (!configuration.isValidConfiguration) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid configuration."];
    }
    self.configuration = [configuration copy];
    self.configuration.settings = self.settings;
    self.networkAPIService = [[BNCNetworkAPIService alloc] initWithConfiguration:configuration];
    self.settings = [BNCSettings loadSettings];

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
}

- (BOOL) isStarted {
    return (self.configuration && self.networkAPIService && self.settings) ? YES : NO;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if TARGET_OS_OSX
    [[NSAppleEventManager sharedAppleEventManager]
        removeEventHandlerForEventClass:kInternetEventClass
        andEventID:kAEGetURL];
#endif
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
    BNCLogMethodName();
    BNCLogDebugSDK(@"userInfo: %@.", notification.userInfo);
}

- (void)applicationWillBecomeActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
    [[Branch sharedInstance]  startNewSession];
}

- (void)applicationDidResignActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
    [[Branch sharedInstance] endSession];
}

- (void) notificationObserver:(NSNotification*)notification {
    //BNCLogDebugSDK(@"Notification '%@'.", notification.name);
}

#pragma mark - Open

- (BOOL) isBranchURL:(NSURL*)url {
    NSString*scheme = [url scheme];
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

        NSTimeInterval kOpenDeadline = 0.200; // TODO: Right delay?

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

- (void) delayedOpen {
    BNCLogMethodName();
    NSURL*url = self.delayedOpenURL;
    self.delayedOpenURL = nil;
    if (self.delayedOpenTimer) {
        dispatch_source_cancel(self.delayedOpenTimer);
        self.delayedOpenTimer = nil;
    }

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

    NSString*scheme = url.scheme;
    if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
        dictionary[@"universal_link_url"] = url.absoluteString;
    } else
    if (scheme.length > 0) {
        dictionary[@"external_intent_uri"] = url.absoluteString;
        NSURLComponents*components = [NSURLComponents componentsWithString:url.absoluteString];
        for (NSURLQueryItem*item in components.queryItems) {
            if ([item.name isEqualToString:@"link_click_id"]) {
                dictionary[@"link_identifier"] = item.value;
                break;
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

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyWillStartSessionWithURL:url];
    });

    __weak __typeof(self) weakSelf = self;
    [self.networkAPIService postOperationForAPIServiceName:service
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation *operation) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf openResponseWithOperation:operation url:url];
        }];
}

- (void) openResponseWithOperation:(BNCNetworkAPIOperation*)operation url:(NSURL*)URL {
    if (operation.error) {
        BNCPerformBlockOnMainThreadSync(^{
            [self notifyDidStartSession:nil withURL:URL error:operation.error];
        });
        return;
    }

    BranchSession*session = operation.session;
    BranchLinkProperties*linkProperties = [BranchLinkProperties linkPropertiesWithDictionary:session.data];
    session.linkProperties = linkProperties;
    BranchUniversalObject*object = [BranchUniversalObject objectWithDictionary:session.data];
    session.linkContent = object;

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyDidStartSession:session withURL:URL error:nil];
    });
    if (session.referringURL) {
        BNCPerformBlockOnMainThreadSync(^ {
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
    Branch*branch = [Branch sharedInstance];
    if ([branch.delegate respondsToSelector:@selector(branch:willStartSessionWithURL:)]) {
        [branch.delegate branch:branch willStartSessionWithURL:URL];
    }
    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchWillStartSessionNotification
        object:branch
        userInfo:userInfo];
}

- (void) notifyDidStartSession:(BranchSession*)session withURL:(NSURL*)URL error:(NSError*)error {
    BNCLogAssert([NSThread isMainThread] && (session || error));
    Branch*branch = [Branch sharedInstance];

    if (session == nil && error == nil) {
        BNCLogError(@"Both session and error are nil!");
        return;
    }

    if (error) {
        if ([branch.delegate respondsToSelector:@selector(branch:failedToStartSessionWithURL:error:)])
            [branch.delegate branch:branch failedToStartSessionWithURL:URL error:error];
    } else {
        if ([branch.delegate respondsToSelector:@selector(branch:didStartSession:)])
            [branch.delegate branch:branch didStartSession:session];
    }

    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    userInfo[BranchSessionKey] = session;
    userInfo[BranchErrorKey] = error;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidStartSessionNotification
        object:branch
        userInfo:userInfo];
}

- (void) notifyDidOpenURLWithSession:(BranchSession*)session {
    BNCLogAssert([NSThread isMainThread]);
    Branch*branch = [Branch sharedInstance];

    if ([branch.delegate respondsToSelector:@selector(branch:didOpenURLWithSession:)])
        [branch.delegate branch:branch didOpenURLWithSession:session];

    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchSessionKey] = session;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidOpenURLWithSessionNotification
        object:branch
        userInfo:userInfo];
}

#pragma mark - Identity

- (void)setIdentity:(NSString*)userID callback:(void (^_Nullable)(NSError*_Nullable error))callback {
    if (!userID || [self.settings.developerIdentityForUser isEqualToString:userID]) {
        if (callback) callback(nil);
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
            BNCPerformBlockOnMainThreadAsync(^{ if (callback) callback(operation.error); });
        }];
}

- (BOOL)userIsIdentified {
    return self.settings.developerIdentityForUser != nil;
}

#pragma mark - Logout

- (void)logoutWithCallback:(void (^_Nullable)(NSError*_Nullable))callback {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"identity_id"] = self.settings.identityID;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/logout"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation * _Nonnull operation) {
            if (!operation.error)
                self.settings.developerIdentityForUser = nil;
            BNCPerformBlockOnMainThreadAsync(^{ if (callback) callback(operation.error); });
        }];
}

#pragma mark - Miscellaneous

- (void) startNewSession {
    [self openURL:nil];
}

- (void) endSession {
    [self sendClose];
}

- (NSMutableDictionary*) requestMetadataDictionary {
    return self.settings.requestMetadataDictionary;
}

- (void) setRequestMetadataDictionary:(NSMutableDictionary *)requestMetadataDictionary {
    self.settings.requestMetadataDictionary = requestMetadataDictionary;
}

- (void) sendClose {
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"identity_id"] = self.settings.identityID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    [self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/close"
        dictionary:dictionary
        completion:nil];
}

#pragma mark - Links

- (void) branchShortLinkWithContent:(BranchUniversalObject*)content
                     linkProperties:(BranchLinkProperties*)linkProperties
                         completion:(void (^)(NSURL*_Nullable shortURL, NSError*_Nullable error))completion {
    if (content == nil || linkProperties == nil) {
        // TODO: Add localized description.
        NSError*error = [NSError branchErrorWithCode:BNCBadRequestError];
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
                NSURL*url = nil;
                NSDictionary*dictionary = nil;
                if ([operation.operation.responseData isKindOfClass:[NSDictionary class]])
                    dictionary = (id) operation.operation.responseData;
                NSString*urlString = dictionary[@"url"];
                if (urlString) url = [NSURL URLWithString:urlString];
                if (url) {
                    if (completion) completion(url, nil);
                    return;
                }
                NSError*error = [NSError branchErrorWithCode:BNCBadRequestError];
                if (completion) completion(nil, error);
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
    addItem(@"source", @"ios"); // TODO

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

@end
