//
//  BNCUserAgentCollector.m
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCUserAgentCollector.h"
#import "BNCDevice.h"
@import WebKit;

// expose a private method on BNCDevice
@interface BNCDevice()
+ (NSString *)systemBuildVersion;
@end

@interface BNCUserAgentCollector()
// need to hold onto the webview until the async user agent fetch is done
@property (nonatomic, strong, readwrite) WKWebView *webview;
@end

@implementation BNCUserAgentCollector

+ (BNCUserAgentCollector *)instance {
    static BNCUserAgentCollector *collector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collector = [BNCUserAgentCollector new];
    });
    return collector;
}

+ (NSString *)userAgentKey {
    return @"BNC_USER_AGENT";
}

+ (NSString *)systemBuildVersionKey {
    return @"BNC_SYSTEM_BUILD_VERSION";
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    [self loadUserAgentForSystemBuildVersion:[BNCDevice systemBuildVersion] withCompletion:completion];
}

- (void)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion withCompletion:(void (^)(NSString *userAgent))completion {
    
    NSString *savedUserAgent = [self loadUserAgentForSystemBuildVersion:systemBuildVersion];
    if (savedUserAgent) {
        self.userAgent = savedUserAgent;
        if (completion) {
            completion(savedUserAgent);
        }
    } else {
        [self collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            self.userAgent = userAgent;
            [self saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
            if (completion) {
                completion(userAgent);
            }
        }];
    }
}

// load user agent from preferences
- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion {
    NSString *userAgent = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedUserAgent = (NSString *)[defaults valueForKey:[BNCUserAgentCollector userAgentKey]];
    NSString *savedSystemBuildVersion = (NSString *)[defaults valueForKey:[BNCUserAgentCollector systemBuildVersionKey]];
    
    if (savedUserAgent && [systemBuildVersion isEqualToString:savedSystemBuildVersion]) {
        userAgent = savedUserAgent;
    }
    return userAgent;
}

// save user agent to preferences
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion {
    if (userAgent && systemBuildVersion) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userAgent forKey:[BNCUserAgentCollector userAgentKey]];
        [defaults setObject:systemBuildVersion forKey:[BNCUserAgentCollector systemBuildVersionKey]];
    }
}

// collect user agent from webkit.  this is expensive.
- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.webview) {
            self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
        }
        
        [self.webview evaluateJavaScript:@"navigator.userAgent;" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            if (completion) {
                if (response) {
                    completion(response);
                
                    // release the webview
                    self.webview = nil;
                } else {
                    // retry if we failed to obtain user agent.  This occurs on iOS simulators.
                    [self collectUserAgentWithCompletion:completion];
                }
            }
        }];
    });
}

@end
