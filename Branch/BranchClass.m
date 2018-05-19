/**
 @file          BranchClass.m
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchClass.h"
#import "BNCLog.h"
#import "BNCNetworkAPIService.h"
#import "BNCSettings.h"

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
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

- (void) startNewSession {
    [self.networkAPIService openURL:nil];
}

- (void) endSession {
    [self.networkAPIService sendClose];
}

- (NSMutableDictionary*) requestMetadataDictionary {
    return self.settings.requestMetadataDictionary;
}

- (void) setRequestMetadataDictionary:(NSMutableDictionary *)requestMetadataDictionary {
    self.settings.requestMetadataDictionary = requestMetadataDictionary;
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
