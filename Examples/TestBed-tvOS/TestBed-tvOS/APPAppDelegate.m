//
//  APPAppDelegate.m
//  TestBed-tvOS
//
//  Created by Edward Smith on 8/1/18.
//  Copyright © 2018 Branch. All rights reserved.
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
@end

@implementation APPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    appDelegate = self;
    originalLogHook = BNCLogOutputFunction();
    BNCLogSetOutputFunction(APPLogHookFunction);
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    BranchConfiguration*configuration =
        [[BranchConfiguration alloc] initWithKey:@"key_live_ait5BYsDbZKRajyPlkzzTancDAp41guC"];

#if 0
    configuration.useCertificatePinning = NO;
    configuration.branchAPIServiceURL = @"http://esmith.api.beta.branch.io";
    configuration.key = @"key_live_ait5BYsDbZKRajyPlkzzTancDAp41guC";
#elif 0
    configuration.useCertificatePinning = NO;
    configuration.branchAPIServiceURL = @"http://cjones.api.beta.branch.io";
    configuration.key = @"key_live_ocyWSee4dsA1EUPxxMvFchefuqdjuxyW";
#else
    configuration.useCertificatePinning = YES;
    configuration.branchAPIServiceURL = @"https://api.branch.io";
    configuration.key = @"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N";
#endif

    [[Branch sharedInstance] startWithConfiguration:configuration];

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
    return YES;
}

#if __TV_OS_VERSION_MAX_ALLOWED < __TVOS_12_0

- (BOOL)application:(UIApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
          restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>>*_Nullable restorableObjects))restorationHandler {
    [Branch.sharedInstance continueUserActivity:userActivity];
    return YES;
}

#else

- (BOOL)application:(UIApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
          restorationHandler:(void(^)(NSArray*_Nullable restorableObjects))restorationHandler {
    [Branch.sharedInstance continueUserActivity:userActivity];
    return YES;
}

#endif

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [Branch.sharedInstance openURL:url options:options];
    return YES;
}

#pragma mark - Display Log Messages

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
            self.viewController.requestTextView.text = message;
        });
    } else
    if ([self string:message matchesRegex:
            @"^\\[branch\\.io\\] BNCNetworkService\\.m\\([0-9]+\\) Debug: Network finish"]) {
        BNCPerformBlockOnMainThreadAsync(^{
            self.viewController.responseTextView.text = message;
        });
    }
}

#pragma mark - Branch Notifications

- (void) branchWillStartSession:(NSNotification*)notification {
    [self.viewController clearUIFields];
    self.viewController.stateField.text = notification.name;
    
    NSURL*url = notification.userInfo[BranchURLKey];
    if (url) self.viewController.urlField.text = url.absoluteString;
}

- (void) branchDidStartSession:(NSNotification*)notification {
    self.viewController.stateField.text = notification.name;

    NSURL*url = notification.userInfo[BranchURLKey];
    if (url) self.viewController.urlField.text = url.absoluteString;

    NSError*error = notification.userInfo[BranchErrorKey];
    self.viewController.errorField.text = error.localizedDescription;

    BranchSession*session = notification.userInfo[BranchSessionKey];
    NSString*data = (session && session.data) ? session.data.description : @"";
    self.viewController.dataTextView.text = data;
}

- (void) branchOpenedURLNotification:(NSNotification*)notification {
    self.viewController.stateField.text = notification.name;
}

@end
