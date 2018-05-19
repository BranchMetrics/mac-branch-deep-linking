/**
 @file          BNCSettings.m
 @package       Branch-SDK
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCSettings.h"
#import "BNCEncoder.h"

@implementation BNCSettings

+ (instancetype) sharedInstance {
    static BNCSettings*sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [self loadSettings];
    });
    return sharedInstance;
}

+ (instancetype) loadSettings {
    BNCSettings* settings = nil;
    NSData*data = BNCPersistenceLoadDataNamed(@"io.branch.sdk.settings");
    if (data) settings = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([settings isKindOfClass:BNCSettings.class]) return settings;
    return [[BNCSettings alloc] init];
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    [BNCEncoder decodeInstance:self withCoder:aDecoder ignoring:nil];
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:nil];
}

- (void) save {
    @synchronized(self) {
        NSData*data = [NSKeyedArchiver archivedDataWithRootObject:self];
        BNCPersistenceSaveDataNamed(@"io.branch.sdk.settings", data);
    }
}

@end

#pragma mark - BNCPersistence

NSData*_Nullable BNCPersistenceLoadDataNamed(NSString*name) {
    return nil;
}

void BNCPersistenceSaveDataNamed(NSString*name, NSData*data) {
}
