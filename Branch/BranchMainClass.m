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
#import "BranchError.h"
#import "NSString+Branch.h"

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
- (void) startNewSession;
- (void) endSession;
@property (readwrite) BNCNetworkAPIService* networkAPIService;
@property (atomic, strong) BranchConfiguration* configuration;
@property (atomic, strong) BNCSettings* settings;
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
    // Put a reference somewhere to these so the linker knows to load the categories.
    BNCForceNSErrorCategoryToLoad();
    BNCForceNSStringCategoryToLoad();

    self.configuration = configuration;
    self.networkAPIService = [[BNCNetworkAPIService alloc] initWithConfiguration:configuration];
    self.settings = [BNCSettings sharedInstance];

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

    // TODO: This is for debugging only.  Remove it.
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(notificationObserver:)
        name:nil
        object:nil];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSAppleEventManager sharedAppleEventManager]
        removeEventHandlerForEventClass:kInternetEventClass
        andEventID:kAEGetURL];
}

#pragma mark - Application State Changes

- (void)urlAppleEvent:(NSAppleEventDescriptor *)event
        withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSAppleEventDescriptor*descriptor = [event paramDescriptorForKeyword:keyDirectObject];
    NSURL *url = [NSURL URLWithString:descriptor.stringValue];
    BNCLogDebugSDK(@"Apple event URL: %@.", url);
    [self openURL:url];
}

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

- (BOOL) openURL:(NSURL*)url {
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

    // TODO: Fix this to return probability of open URL in service:
    return YES;
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

//  TODO: Send intrumentation.
//  preferenceHelper.previousAppBuildDate = [BNCApplication currentApplication].currentBuildDate;

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyDidStartSession:session withURL:URL error:nil];
    });
    if (session.referringURL) {
        BNCPerformBlockOnMainThreadSync(^ {
            [self notifyDidOpenURLWithSession:session];
        });
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

- (void)setIdentity:(NSString*)userID callback:(void (^_Nullable)(NSError*_Nullable))callback {
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
            BNCPerformBlockOnMainThreadSync(^{ if (callback) callback(operation.error); });
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
            BNCPerformBlockOnMainThreadSync(^{
            if (callback) callback(operation.error); });
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

@end
