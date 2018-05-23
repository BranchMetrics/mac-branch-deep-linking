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

#include "Branch/BNCLog.h"

@interface APPAppDelegate ()
@property (strong, nonatomic) APPViewController*viewController;
@end

@implementation APPAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    BranchConfiguration*configuration = [[BranchConfiguration alloc] init];
    configuration.key = @"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N";
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
        restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    BNCLogMethodName();
    return YES;
}

#pragma mark - Branch Notifications

- (void) branchWillStartSession:(NSNotification*)notification {
    [self.viewController.window makeKeyAndOrderFront:self];
    self.viewController.stateField.stringValue = notification.name;
    self.viewController.urlField.stringValue   = notification.userInfo[BranchURLKey] ?: @"";
    self.viewController.errorField.stringValue = @"< No Error >";
    self.viewController.dataField.stringValue  = @"< No Data >";
}

- (void) branchDidStartSession:(NSNotification*)notification {
    self.viewController.stateField.stringValue = notification.name;
    self.viewController.urlField.stringValue   = notification.userInfo[BranchURLKey] ?: @"";
    self.viewController.errorField.stringValue = notification.userInfo[BranchErrorKey] ?: @"";
    BranchSession*session = notification.userInfo[BranchSessionKey];
    NSString*data = (session && session.data) ? session.data.description : @"< No Data >";
    self.viewController.dataField.stringValue  = data;
}

- (void) branchOpenedURLNotification:(NSNotification*)notification {
    self.viewController.stateField.stringValue = notification.name;
}

#if 0
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    BNCPerformBlockOnMainThreadAsync(^{
        BNCLogMethodName();
        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = @"Open URL";
        alert.informativeText = [NSString stringWithFormat:@"%@", urls];
        [alert runModal];
    });
}
#endif

@end
