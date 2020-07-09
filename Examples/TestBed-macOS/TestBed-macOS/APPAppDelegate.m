//
//  APPAppDelegate.m
//  TestBed-Mac
//
//  Created by Edward Smith on 5/15/18.
//  Copyright © 2018 Edward Smith. All rights reserved.
//

#import "APPAppDelegate.h"
#import "APPViewController.h"
#import <Branch/Branch.h>
#import <Branch/BNCLog.h>
#import "../../../Branch/BNCThreads.h"

static APPAppDelegate* appDelegate = nil;
static BNCLogOutputFunctionPtr originalLogHook = NULL;

void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);
void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    [appDelegate processLogMessage:message];
    if (originalLogHook) {
        originalLogHook(timestamp, level, message);
    }
}

@interface APPAppDelegate ()
@property (strong, nonatomic) APPViewController*viewController;
@end

@implementation APPAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    appDelegate = self;
    originalLogHook = BNCLogOutputFunction();
    BNCLogSetOutputFunction(APPLogHookFunction);
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchWillStartSession:)
        name:BranchWillStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSession:)
        name:BranchDidStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchOpenedURLNotification:)
        name:BranchDidOpenURLWithSessionNotification
        object:nil];

    BranchConfiguration *configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_ait5BYsDbZKRajyPlkzzTancDAp41guC"];

    configuration.branchAPIServiceURL = @"https://api.branch.io";
    configuration.key = @"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N";

    [[Branch sharedInstance] startWithConfiguration:configuration];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.viewController = [APPViewController loadController];
    [self.viewController.window makeKeyAndOrderFront:self];
}

- (BOOL)application:(NSApplication *)application
willContinueUserActivityWithType:(NSString *)userActivityType {
    BNCLogMethodName();
    return YES;
}

- (BOOL)application:(NSApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
restorationHandler:(void(^)(NSArray<id<NSUserActivityRestoring>> *restorableObjects))restorationHandler {
    BNCLogMethodName();
    [[Branch sharedInstance] continueUserActivity:userActivity];
    return YES;
}

- (BOOL) string:(NSString*)string matchesRegex:(NSString*)regex {
    NSError *error = NULL;
    NSRegularExpression *ns_regex =
        [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
    NSRange range = [ns_regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return (range.location == NSNotFound) ? NO : YES;
}

- (void) processLogMessage:(NSString *)message {
    if ([self string:message matchesRegex:
            @"^\\[branch\\.io\\] BNCNetworkService\\.m\\([0-9]+\\) Debug: Network start"]) {
        BNCPerformBlockOnMainThreadAsync(^{
            self.viewController.requestTextView.string = message;
        });
    } else
    if ([self string:message matchesRegex:
            @"^\\[branch\\.io\\] BNCNetworkService\\.m\\([0-9]+\\) Debug: Network finish"]) {
        BNCPerformBlockOnMainThreadAsync(^{
            self.viewController.responseTextView.string = message;
        });
    }
}

#pragma mark - Branch Notifications

- (void) branchWillStartSession:(NSNotification*)notification {
    [self.viewController clearUIFields];
    [self.viewController.window makeKeyAndOrderFront:self];
    self.viewController.stateField.stringValue = notification.name;
    self.viewController.urlField.stringValue   = notification.userInfo[BranchURLKey] ?: @"";
}

- (void) branchDidStartSession:(NSNotification*)notification {
    self.viewController.stateField.stringValue = notification.name;
    self.viewController.urlField.stringValue   = notification.userInfo[BranchURLKey] ?: @"";
    self.viewController.errorField.stringValue = notification.userInfo[BranchErrorKey] ?: @"";
    BranchSession*session = notification.userInfo[BranchSessionKey];
    NSString*data = (session && session.data) ? session.data.description : @"";
    self.viewController.dataTextView.string = data;
}

- (void) branchOpenedURLNotification:(NSNotification*)notification {
    self.viewController.stateField.stringValue = notification.name;
}

@end
