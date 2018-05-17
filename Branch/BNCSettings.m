/**
 @file          BNCSettings.m
 @package       Branch-SDK
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCSettings.h"

@implementation BNCSettings

+ (instancetype) sharedInstance {
    static BNCSettings*sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [[BNCSettings alloc] init];
    });
    return sharedInstance;
}

@end
