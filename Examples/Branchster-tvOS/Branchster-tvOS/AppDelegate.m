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
    BranchConfiguration*configuration =
        [[BranchConfiguration alloc] initWithKey:@"key_live_hkDytPACtipny3N9XmnbZlapBDdj4WIL"];
    [[Branch sharedInstance] startWithConfiguration:configuration];

    return YES;
}

- (BOOL)application:(UIApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
        restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
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

- (void) showMonster:(BranchUniversalObject*)monster {
    MonsterCreatorViewController *creator = [MonsterCreatorViewController viewControllerWithMonster:monster];
    MonsterViewerViewController *viewer = [MonsterViewerViewController viewControllerWithMonster:monster];
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
        [self showMonster:buo];
    } else
    if (isFirstTime) {
        [self editMonster:BranchUniversalObject.emptyMonster];
    }
}

@end
