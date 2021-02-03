//
//  AppDelegate.m
//  TestDeepLinking
//
//  Created by Nidhi on 2/3/21.
//

#import "AppDelegate.h"
#import <Branch/Branch.h>
#import <Branch/BNCLog.h>
#import <Branch/BNCThreads.h>

static AppDelegate* appDelegate = nil;
static BNCLogOutputFunctionPtr originalLogHook = NULL;

void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);
void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    [appDelegate processLogMessage:message];
    if (originalLogHook) {
        originalLogHook(timestamp, level, message);
    }
}

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    appDelegate = self;
    originalLogHook = BNCLogOutputFunction();
    BNCLogSetOutputFunction(APPLogHookFunction);
    BNCLogSetDisplayLevel(BNCLogLevelAll);
    
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

    BranchConfiguration *configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_ait5BYsDbZKRajyPlkzzTancDAp41guC"];

    configuration.branchAPIServiceURL = @"https://api.branch.io";
    configuration.key = @"key_live_jcZkwmLUm17zGqCXKyh6QjdiAyjDodHI";

    [[Branch sharedInstance] startWithConfiguration:configuration];
}

- (BOOL) string:(NSString*)string matchesRegex:(NSString*)regex {
    NSError *error = NULL;
    NSRegularExpression *ns_regex =
        [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
    NSRange range = [ns_regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return (range.location == NSNotFound) ? NO : YES;
}


- (void) processLogMessage:(NSString *)message {
    if (([self string:message matchesRegex:
            @"^\\[branch\\.io\\] BNCNetworkService\\.m\\([0-9]+\\) Debug: Network start"])&&
        ([message containsString:@"https://cdn.branch.io/sdk/uriskiplist_v0.json"] == NO)) {
        BNCPerformBlockOnMainThreadAsync(^{
            
            NSLog(@"---------------\n%@\n--------------", message);
           // self.viewController.requestTextView.string = message;
        });
    } else
    if (([self string:message matchesRegex:
            @"^\\[branch\\.io\\] BNCNetworkService\\.m\\([0-9]+\\) Debug: Network finish"])&&
        ([message containsString:@"https://cdn.branch.io/sdk/uriskiplist_v0.json"] == NO)) {
        BNCPerformBlockOnMainThreadAsync(^{
            //self.viewController.responseTextView.string = message;
        });
    }
}


#pragma mark - Branch Notifications

- (void) branchWillStartSession:(NSNotification*)notification {
    self.notification.stringValue = notification.name;
}

- (void) branchDidStartSession:(NSNotification*)notification {
    
    BranchSession *session = notification.userInfo[BranchSessionKey];

    NSString *data = (session && session.data) ? session.data.description : @"";
    self.sessionData.string = data ;
    
}

- (void) branchOpenedURLNotification:(NSNotification*)notification {
    self.notification.stringValue = notification.name;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
