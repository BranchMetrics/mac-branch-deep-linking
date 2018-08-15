//
//  AppDelegate.m
//  Branchster-macOS
//
//  Created by Edward on 8/14/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "AppDelegate.h"
@import Branch;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSession:)
        name:BranchDidStartSessionNotification
        object:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (void) branchDidStartSession:(NSNotification*)notification {
    self.viewController.stateField.stringValue = notification.name;
    self.viewController.urlField.stringValue   = notification.userInfo[BranchURLKey] ?: @"";
    self.viewController.errorField.stringValue = notification.userInfo[BranchErrorKey] ?: @"";
    BranchSession*session = notification.userInfo[BranchSessionKey];
    NSString*data = (session && session.data) ? session.data.description : @"";
    self.viewController.dataTextView.string = data;
}

@end
