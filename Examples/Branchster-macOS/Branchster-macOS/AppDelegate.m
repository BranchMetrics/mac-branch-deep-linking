//
//  AppDelegate.m
//  Branchster-macOS
//
//  Created by Edward Smith on 8/14/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "AppDelegate.h"
#import "MonsterWindowController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
@import Branch;

@implementation AppDelegate

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];
    BranchConfiguration*configuration =
        [[BranchConfiguration alloc] initWithKey:@"key_live_hkDytPACtipny3N9XmnbZlapBDdj4WIL"];
    [Branch.sharedInstance startWithConfiguration:configuration];

    [NSApplication.sharedApplication activateIgnoringOtherApps:YES];
    [MonsterWindowController newWindowWithMonster:nil];
}

- (BOOL)application:(NSApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void (^)(NSArray<id<NSUserActivityRestoring>> *restorableObjects))restorationHandler {
  return [Branch.sharedInstance continueUserActivity:userActivity];
}

- (void) branchDidStartSessionNotification:(NSNotification*)notification {
    BranchSession*session = notification.userInfo[BranchSessionKey];
    BranchUniversalObject*monster = session.linkContent;
    MonsterWindowController*controller = nil;

    static BOOL isFirstTime = YES;
    if (isFirstTime) {
        isFirstTime = NO;
        if (!monster.isMonster) {
            controller = NSApplication.sharedApplication.windows.firstObject.windowController;
            controller.monster = [BranchUniversalObject newEmptyMonster];
            [controller editMonster:self];
            return;
        }
    }
    if (!monster.isMonster) return;

    if (!controller) controller = [MonsterWindowController newWindowWithMonster:monster];
    controller.monster = monster;
    [controller viewMonster:self];
}

- (IBAction) newDocument:(id)sender {
    [MonsterWindowController newWindowWithMonster:[BranchUniversalObject newEmptyMonster]];
}

@end
