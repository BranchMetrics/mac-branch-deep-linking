//
//  AppDelegate.m
//  Branchster-macOS
//
//  Created by Edward on 8/14/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "AppDelegate.h"
#import "MonsterWindowController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
@import Branch;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
//    [[NSNotificationCenter defaultCenter]
//        addObserver:self
//        selector:@selector(logMessageNotification:)
//        name:nil
//        object:nil];

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

- (void) logMessageNotification:(NSNotification*)notification {
    BNCLogDebug(@"%@", notification.name);
}

- (void) branchDidStartSessionNotification:(NSNotification*)notification {
    BranchSession*session = notification.userInfo[BranchSessionKey];
    BranchUniversalObject*monster = session.linkContent;

    static BOOL isFirstTime = YES;
    if (isFirstTime) {
        isFirstTime = NO;
        if (!monster.isMonster) monster = [BranchUniversalObject newEmptyMonster];
    }
    if (!monster.isMonster) return;

    // Find a window for the monster:
    for (NSWindow*window in [NSApplication sharedApplication].windows) {
        MonsterWindowController*controller = window.windowController;
        if ([controller isKindOfClass:MonsterWindowController.class] && controller.monster == nil) {
            controller.monster = monster;
            return;
        }
    }

    // No windows are available. Make a new one.
    if (monster.isMonster)
        [MonsterWindowController newWindowWithMonster:monster];
}

- (IBAction) newDocument:(id)sender {
    [MonsterWindowController newWindowWithMonster:[BranchUniversalObject newEmptyMonster]];
}

@end
