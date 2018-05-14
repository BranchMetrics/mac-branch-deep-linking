/**
 @file          Branch.m
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "Branch.h"
#import <AppKit/AppKit.h>

#pragma mark BranchConfiguration

@implementation BranchConfiguration
@end

#pragma mark - Branch

@interface Branch ()
@property (nonatomic, strong) BranchConfiguration*configuration;
@end

@implementation Branch

+ (instancetype) sharedInstance {
    static Branch*sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [[Branch alloc] init];
    });
    return sharedInstance;
}

- (void) startWithConfiguration:(BranchConfiguration*)configuration {
    self.configuration = configuration;
    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(applicationDidFinishLaunchingNotification:)
        name:NSApplicationDidFinishLaunchingNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(applicationWillBecomeActiveNotification:)
        name:NSApplicationWillBecomeActiveNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(applicationWillResignActiveNotification:)
        name:NSApplicationWillResignActiveNotification
        object:nil];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSString *)bundleIdentifier {
    NSString*_Nullable string =
        [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey];
    return string?:@"";
}

+ (NSString *)kitDisplayVersion {
    NSString*_Nullable string =
        [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return string?:@"";
}

#pragma mark - Application State Changes

- (void)applicationDidFinishLaunchingNotification:(NSNotification*)notification {
}

- (void)applicationWillBecomeActiveNotification:(NSNotification*)notification {
}

- (void)applicationWillResignActiveNotification:(NSNotification*)notification {
}

@end
