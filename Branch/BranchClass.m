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

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
@property (atomic, strong) BranchConfiguration* configuration;
@property (atomic, strong) BNCNetworkAPIService* networkAPIService;
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

- (void) startWithConfiguration:(BranchConfiguration*)configuration {
    self.configuration = configuration;
    self.networkAPIService = [[BNCNetworkAPIService alloc] initWithConfiguration:configuration];

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

+ (NSString *)bundleIdentifier {
    NSString*_Nullable string =
        [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey];
    return string?:@"";
}

+ (NSString *)kitDisplayVersion {
    NSString*_Nullable string =
        [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return string?:@"";
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
