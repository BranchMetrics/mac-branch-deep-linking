//
//  TBAppDelegate.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBBranchViewController.h"
#import "TBDetailViewController.h"
#import "TBTextViewController.h"
@import Branch;
//#import "../../../Branch/BranchMainClass+Private.h"
//#import "../../../Branch/BNCSettings.h"
#import "../../../Branch/BNCApplication.h"

NSDate *global_previous_update_time = nil;
NSDate *next_previous_update_time = nil;

@interface TBAppDelegate () <UISplitViewControllerDelegate>
@property (nonatomic, strong) TBBranchViewController*branchViewController;
@property (nonatomic, strong) UISplitViewController*splitViewController;
@end

#pragma mark - TBAppDelegate

@implementation TBAppDelegate

#pragma mark - Life Cycle Methods

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    // Set to YES for testing GDPR compliance.
    // [Branch setTrackingDisabled:YES];

    #if 0
    // This simulates tracking opt-in, rather than tracking opt-out.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
        [Branch setTrackingDisabled:YES];
    }
    #endif

    // Initialize Branch
    BranchConfiguration*config =
        [[BranchConfiguration alloc] initWithKey:@"key_live_hiCNKmaPecgH3UenloTtopoevBb16rfY"];
    [Branch.sharedInstance startWithConfiguration:config];

    // For testing app updates:
    next_previous_update_time = [BNCApplication currentApplication].previousAppBuildDate;

    BNCLogSetDisplayLevel(BNCLogLevelAll);
    Branch.sharedInstance.sessionStartedBlock =
        ^ (BranchSession * _Nullable session, NSError * _Nullable error) {
            [self handleBranchDeepLinkSession:session error:error];
            global_previous_update_time = next_previous_update_time;
            next_previous_update_time = [BNCApplication currentApplication].previousAppBuildDate;
        };

    [self initializeViewControllers];

    return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    BNCLogMethodName();

    // Required. Returns YES if Branch link, else returns NO
    [Branch.sharedInstance openURL:url options:options];

    // Process non-Branch URIs here...
    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void (^)(NSArray *))restorationHandler {

    NSLog(@"application:continueUserActivity:restorationHandler: invoked.\n"
           "ActivityType: %@ userActivity.webpageURL: %@",
           userActivity.activityType,
           userActivity.webpageURL.absoluteString);

    // Required. Returns YES if Branch Universal Link, else returns NO.
    // Add `branch_universal_link_domains` to .plist (String or Array) for custom domain(s).
    [Branch.sharedInstance continueUserActivity:userActivity];

    // Process non-Branch userActivities here...
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    BNCLogMethodName();
}

#pragma mark - View Controllers


- (void)handleBranchDeepLinkSession:(BranchSession*)session error:(NSError*)error {
    if (error) {
        [self showDataViewControllerWithTitle:@"Error"
            message:@"Error opening Branch link"
            object:@{@"Error": error.description}];
    } else {
        [self showDataViewControllerWithTitle:@"Opened URL"
            message:session.referringURL.absoluteString
            object:session.data];
    }
}

- (void) showDataViewControllerWithTitle:(NSString*)title
                                 message:(NSString*)message
                                  object:(id<NSObject>)dictionaryOrArray {

    TBDetailViewController *dataViewController =
        [[TBDetailViewController alloc] initWithData:dictionaryOrArray];
    dataViewController.title = title;
    dataViewController.message = message;

    // Manage the display mode button
//    dataViewController.navigationItem.leftBarButtonItem =
//        self.splitViewController.displayModeButtonItem;
//    dataViewController.navigationItem.leftItemsSupplementBackButton = YES;

    [self.splitViewController showDetailViewController:dataViewController sender:self];
}

- (void)initializeViewControllers {

    // Set the split view delegate:
    self.splitViewController = (UISplitViewController *)self.window.rootViewController;

    self.branchViewController = [TBBranchViewController new];
    UINavigationController *masterViewController =
        [[UINavigationController alloc]
            initWithRootViewController:self.branchViewController];
    masterViewController.title = @"Branch";

    TBDetailViewController *detailViewController = [TBDetailViewController new];
    UINavigationController *detailNavigationViewController =
        [[UINavigationController alloc] initWithRootViewController:detailViewController];

    self.splitViewController.viewControllers = @[masterViewController, detailNavigationViewController];

    // Set up the navigation controller button:
//    detailNavigationViewController.topViewController.navigationItem.leftBarButtonItem =
//        splitViewController.displayModeButtonItem;
//    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    self.splitViewController.delegate = self;
}

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlock(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

- (void) presentModalViewController:(UIViewController*)viewController {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    window.backgroundColor = [UIColor clearColor];

    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    // Applications that does not load with UIMainStoryboardFile might not have a window property:
    if ([delegate respondsToSelector:@selector(window)]) {
        // Inherit the main window's tintColor
        window.tintColor = delegate.window.tintColor;
    }

    // Window level is above the top window (this makes the alert, if it's a sheet, show over the keyboard)
    UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
    window.windowLevel = topWindow.windowLevel + 1;

    [window makeKeyAndVisible];
    BNCAfterSecondsPerformBlock(0.10, ^{
        [window.rootViewController presentViewController:viewController animated:YES completion:nil];
    });
}

- (void) dismissLastModalViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController dismissViewControllerAnimated:YES completion:^ {
        window.rootViewController = nil;
        window.hidden = YES;
    }];
}

- (IBAction)dismissLinkViewAction:(id)sender {
    [self dismissLastModalViewController];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
      ontoPrimaryViewController:(UIViewController *)primaryViewController {

    UINavigationController *navigationController = nil;
    TBDetailViewController *detailViewController = nil;

    if ([secondaryViewController isKindOfClass:[UINavigationController class]])
        navigationController = (id) secondaryViewController;

    if ([[navigationController topViewController] isKindOfClass:[TBDetailViewController class]])
        detailViewController = (id) [navigationController topViewController];

    if (detailViewController && detailViewController.dictionaryOrArray == nil)
        return YES;

    return NO;
}

@end
