/**
 @file          BranchMain.m
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchMain.h"
#import "BNCLog.h"
#import <AppKit/AppKit.h>

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
@property (nonatomic, strong) BranchConfiguration*configuration;
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
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (BOOL) openBranchURL:(NSURL*)url {
    return NO;
}

#pragma mark - Application State Changes

- (void)applicationDidFinishLaunchingNotification:(NSNotification*)notification {
    BNCLogMethodName();
    BNCLogDebugSDK(@"userInfo: %@.", notification.userInfo);
}

- (void)applicationWillBecomeActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
}

- (void)applicationDidResignActiveNotification:(NSNotification*)notification {
    BNCLogMethodName();
}

- (void) notificationObserver:(NSNotification*)notification {
    BNCLogDebugSDK(@"Notification '%@'.", notification.name);
}

@end
