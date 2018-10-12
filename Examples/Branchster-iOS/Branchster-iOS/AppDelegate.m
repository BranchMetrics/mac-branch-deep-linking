//
//  AppDelegate.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

@import Branch;
#import "AppDelegate.h"
#import "SplashViewController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
#import "MonsterCreatorViewController.h"
#import "MonsterViewerViewController.h"

@interface AppDelegate ()
@property (nonatomic) BOOL justLaunched;
@property (nonatomic) UINavigationController*navigationController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BNCLogSetDisplayLevel(BNCLogLevelAll);
    self.justLaunched = YES;
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

    // Optional: Set our own identitier for this user at Branch.
    // This could be an account number our other userID. It only needs to be set once.
    NSString *userIdentity = [[NSUserDefaults standardUserDefaults] objectForKey:@"userIdentity"];
    if (!userIdentity) {
        userIdentity = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userIdentity forKey:@"userIdentity"];
        [Branch.sharedInstance setUserIdentity:userIdentity completion:
            ^(BranchSession * _Nullable session, NSError * _Nullable error) {
                NSLog(@"User identity set:\n%@.", session);
            }
        ];
    }
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

- (void) showMonster:(BranchUniversalObject*)monster monsterURL:(NSURL*)url {
    MonsterCreatorViewController *creator = [MonsterCreatorViewController viewControllerWithMonster:monster];
    MonsterViewerViewController *viewer = [MonsterViewerViewController viewControllerWithMonster:monster monsterURL:url];
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

#if 0
    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandlerUsingBranchUniversalObject:
        ^ (BranchUniversalObject *BUO, BranchLinkProperties *linkProperties, NSError *error) {
            if (linkProperties.controlParams[@"$3p"] &&
                linkProperties.controlParams[@"$web_only"]) {
                NSURL *url = [NSURL URLWithString:linkProperties.controlParams[@"$original_url"]];
                if (url) {
                    [[NSNotificationCenter defaultCenter]
                       postNotificationName:@"pushWebView"
                       object:self
                       userInfo:@{@"URL": url}];
               }
            } else
            if (BUO && BUO.contentMetadata.customMetadata[@"monster"]) {
                self.initialMonster = BUO;
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"pushEditAndViewerViews"
                    object:nil];
            } else
            if (self.justLaunched) {
                self.initialMonster = [self emptyMonster];
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"pushEditView"
                    object:nil];
                self.justLaunched = NO;
            }
        }];
#endif

@end
