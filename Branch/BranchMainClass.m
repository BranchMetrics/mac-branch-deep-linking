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

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
- (void) startNewSession;
- (void) endSession;

@property (atomic, strong) BranchConfiguration* configuration;
@property (atomic, strong) BNCNetworkAPIService* networkAPIService;
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
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(notificationObserver:)
        name:nil
        object:nil];
    [[NSAppleEventManager sharedAppleEventManager]
        setEventHandler:self
        andSelector:@selector(urlAppleEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
        andEventID:kAEGetURL];
}

- (void)urlAppleEvent:(NSAppleEventDescriptor *)event
        withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSAppleEventDescriptor*descriptor = [event paramDescriptorForKeyword:keyDirectObject];
    NSURL *url = [NSURL URLWithString:descriptor.stringValue];
    BNCLogDebugSDK(@"Apple event URL: %@.", url);
    [self openURL:url];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSAppleEventManager sharedAppleEventManager]
        removeEventHandlerForEventClass:kInternetEventClass
        andEventID:kAEGetURL];
}

- (BOOL) openURL:(NSURL*)url {
    [self.networkAPIService openURL:url];
    return YES;
}

- (void)setIdentity:(NSString*)userID
       withCallback:(void (^_Nullable)(NSDictionary*_Nullable, NSError*_Nullable))callback {
    if (!userID || [self.settings.developerIdentityForUser isEqualToString:userID]) {
        if (callback) {
        // callback([self getFirstReferringParams], nil);
        }
        return;
    }
    // [self initSessionIfNeededAndNotInProgress];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"identity"] = userID;
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"identity_id"] = self.settings.identityID;
    //[self.networkAPIService appendV1APIParametersWithDictionary:dictionary];
    [self.networkAPIService postOperationForAPIServiceName:@"v1/profile"
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation*_Nonnull operation) {
            if (operation.error) {
                BNCPerformBlockOnMainThreadSync(^{
        //            [self notifyDidStartSession:nil withURL:URL error:operation.error];
                });
                return;
            }

        }];
}

- (BOOL)isUserIdentified {
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
            NSError* error = [self logoutResponseWithOperation:operation];
            BNCPerformBlockOnMainThreadSync(^{
                if (callback) callback(error);
            });
        }];
}

- (NSError*) logoutResponseWithOperation:(BNCNetworkAPIOperation*)operation {
    if (operation.error) return operation.error;
    self.settings.sessionID = operation.session.sessionID;
    self.settings.identityID = operation.session.identityID;
    self.settings.linkCreationURL = operation.session.linkCreationURL;
    self.settings.developerIdentityForUser = nil;
    //self.settings.installParams = nil;
    //[self.settings clearUserCreditsAndCounts];
    return nil;
}

- (void) startNewSession {
    [self.networkAPIService openURL:nil];
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

#pragma mark - Application State Changes

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

@end
