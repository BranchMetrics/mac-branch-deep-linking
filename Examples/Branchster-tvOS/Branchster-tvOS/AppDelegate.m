//
//  AppDelegate.m
//  Branchster-tvOS
//
//  Created by Edward Smith on 8/13/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "AppDelegate.h"
#import "MonsterCreatorViewController.h"
#import "MonsterViewerViewController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
@import Branch;

@interface AppDelegate ()
@property (nonatomic, strong) UINavigationController*navigationController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchCloudShareNotification:)
        name:BranchCloundShareNotification
        object:nil];
    BranchConfiguration*configuration =
        [[BranchConfiguration alloc] initWithKey:@"key_live_hkDytPACtipny3N9XmnbZlapBDdj4WIL"];
    [[Branch sharedInstance] startWithConfiguration:configuration];
    [Branch.sharedInstance startCloudShareNotifications];
    return YES;
}

- (BOOL)application:(UIApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
        restorationHandler:(void (^)(NSArray<id <UIUserActivityRestoring>>
            *restorableObjects))restorationHandler {
    [Branch.sharedInstance continueUserActivity:userActivity];
    return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [Branch.sharedInstance openURL:url options:options];
    return YES;
}

#pragma mark - Navigation

- (void) editMonster:(BranchUniversalObject*)monster {
    MonsterCreatorViewController *creator = [MonsterCreatorViewController viewControllerWithMonster:monster];
    [self.navigationController setViewControllers:@[creator] animated:YES];
}

- (void) showMonster:(BranchUniversalObject*)monster monsterURL:(NSURL*)URL {
    MonsterCreatorViewController *creator = [MonsterCreatorViewController viewControllerWithMonster:monster];
    MonsterViewerViewController *viewer =
        [MonsterViewerViewController viewControllerWithMonster:monster monsterURL:URL];
    [self.navigationController setViewControllers:@[creator, viewer] animated:YES];
}

- (void) branchDidStartSessionNotification:(NSNotification*)notification {
    BOOL isFirstTime = NO;
    if (!self.navigationController) {
        isFirstTime = YES;
        self.navigationController = (id) self.window.rootViewController;
    }
    BranchSession*session = notification.userInfo[BranchSessionKey];
    BranchUniversalObject*buo = session.linkContent;
    if (buo.isMonster) {
        [self showMonster:buo monsterURL:session.referringURL];
    } else
    if (isFirstTime) {
        [self editMonster:BranchUniversalObject.emptyMonster];
    }
}

- (void) branchCloudShareNotification:(NSNotification*)notification {
    BranchCloudShareItem*item = notification.userInfo[BranchCloundShareItemKey];
    if (!item) return;

    __auto_type message =
        [NSString stringWithFormat:@"There's a new scary monster!\nShow '%@'?", item.contentTitle];

    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Show Monster?"
            message:message
            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {
                [Branch.sharedInstance openURL:item.contentURL];
            }]];
    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel
            handler:nil]];
    [UIViewController.bnc_currentViewController presentViewController:alert animated:YES completion:nil];
}

@end
