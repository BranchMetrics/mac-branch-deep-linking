/**
 @file          BranchCloudShare.m
 @package       Branch
 @brief         Share links in iCloud

 @author        Edward Smith
 @date          October 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "Branch+CloudShare.h"
#import "BranchMainClass+Private.h"
#import "BNCEncoder.h"
#import "BNCDevice.h"
#import "BNCThreads.h"
#import "BNCLog.h"

NSString*const BranchCloundShareNotification = @"BranchCloundShareNotification";
NSString*const BranchCloundShareItemKey      = @"BranchCloundShareItemKey";

static NSString*const BranchCloudShareKey     = @"io.branch.sdk.CloudShare";
static NSString*const BranchCloudShareDateKey = @"io.branch.sdk.CloudShareDate";

@implementation BranchCloudShareItem

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)coder {
    self = [super init];
    __auto_type error = [BNCEncoder decodeInstance:self withCoder:coder ignoring:nil];
    if (error) self = [[BranchCloudShareItem alloc] init];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:nil];
}

@end

#pragma mark - BNCCloudShare

@interface BNCCloudShare : NSObject <NSUserActivityDelegate>
- (void) start;
- (void) stop;
- (void) updateItem:(BranchCloudShareItem*)item;

@property (strong) NSUbiquitousKeyValueStore*cloudStore;
@property (strong) BranchCloudShareItem*cloudShareItem;
@property (strong) NSUserActivity*userActivity;
@property (strong) NSDate*lastUpdateDate;
@property (strong) NSTimer*timer;
@end

@implementation BNCCloudShare

- (void) start {
    // Already started?
    if (self.cloudStore) return;

    // Start notifications:
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(cloudUpdateNotification:)
        name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
        object:nil];
    self.cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    self.lastUpdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"cloudUpdateDate"];
    [self.cloudStore synchronize];
    self.timer =
        [NSTimer scheduledTimerWithTimeInterval:5.0
            target:self
            selector:@selector(timerUpdate:)
            userInfo:nil
            repeats:YES];
    [self refreshFromCloud];
}

- (void) timerUpdate:(NSTimer*)update {
    [self.cloudStore synchronize];
}

- (void) stop {
    [self.timer invalidate];
    self.timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.cloudStore = nil;
}

- (void) dealloc {
    [self stop];
}

- (void) updateItem:(BranchCloudShareItem *)item {
    if (!item) return;
    item.updateDate = [NSDate date];
    item.deviceName = [BNCDevice currentDevice].deviceName;
    self.cloudShareItem = item;
    self.lastUpdateDate = item.updateDate;
    [[NSUserDefaults standardUserDefaults] setObject:self.lastUpdateDate forKey:@"cloudUpdateDate"];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData*data = [NSKeyedArchiver archivedDataWithRootObject:item];
    if (!data) return;
    #pragma clang diagnostic pop

    [self.cloudStore setObject:data forKey:BranchCloudShareKey];
    [self.cloudStore setObject:item.updateDate forKey:BranchCloudShareDateKey];
    [self.cloudStore synchronize];

    self.userActivity = [[NSUserActivity alloc] initWithActivityType:item.activityID];
    self.userActivity.delegate = self;
    [self updateUserActivity:self.userActivity];
    [self.userActivity becomeCurrent];
}

- (void) cloudUpdateNotification:(NSNotification*)notification {
    // Notification keys:
    // NSUbiquitousKeyValueStoreChangedKeysKey
    // NSUbiquitousKeyValueStoreChangeReasonKey
    NSArray* updatedKeys = notification.userInfo[NSUbiquitousKeyValueStoreChangedKeysKey];
    if ([updatedKeys containsObject:BranchCloudShareDateKey]) {
        [self refreshFromCloud];
    }
}

- (void) refreshFromCloud {
    NSDate*updateDate = [self.cloudStore objectForKey:BranchCloudShareDateKey];
    NSData*itemData = [self.cloudStore objectForKey:BranchCloudShareKey];
    if (updateDate == nil || itemData == nil) return;

    if (self.lastUpdateDate != nil && [updateDate compare:self.lastUpdateDate] <= 0)
        return;

    BranchCloudShareItem*item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
    if (!item) return;

    self.cloudShareItem = item;
    self.lastUpdateDate = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:self.lastUpdateDate forKey:@"cloudUpdateDate"];

    NSNotification*shareNotification =
        [NSNotification notificationWithName:BranchCloundShareNotification
            object:self
            userInfo:@{
                BranchCloundShareItemKey: self.cloudShareItem
            }
        ];
    BNCPerformBlockOnMainThreadAsync(^{
        [[NSNotificationCenter defaultCenter] postNotification:shareNotification];
    });
}

- (void) updateUserActivity:(NSUserActivity*)activity {
    activity.title = self.cloudShareItem.contentTitle;
    //activity.keywords = [NSSet setWithArray:@[ @"Branch", @"Monster", @"Factory" ]];
    activity.requiredUserInfoKeys = [NSSet setWithArray:@[ @"branch" ]];
    [activity addUserInfoEntriesFromDictionary:@{ @"branch": self.cloudShareItem.contentURL }];
    activity.eligibleForSearch = YES;
    activity.eligibleForHandoff = YES;
    activity.eligibleForPublicIndexing = YES;
    activity.webpageURL = self.cloudShareItem.contentURL;
// iOS Only:
//    self.activity.eligibleForPrediction = YES;
//    self.activity.suggestedInvocationPhrase = @"Show Monster";
}

- (void)userActivityWasContinued:(NSUserActivity *)userActivity {
    BNCLogMethodName();
    BNCLogDebug(@"%@", userActivity.userInfo);
}

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    BNCLogMethodName();
    BNCLogDebug(@"before userInfo %@", userActivity.userInfo);
    [self updateUserActivity:userActivity];
    BNCLogDebug(@" after userInfo %@", userActivity.userInfo);
}

@end

#pragma mark - Branch

@interface Branch (BranchCloudSharePrivate)
@property (atomic, strong) BNCCloudShare*cloudShare;
@end

@implementation Branch (BranchCloudShare)

- (void) startCloudShareNotifications {
    if (self.cloudShare == nil) self.cloudShare = [[BNCCloudShare alloc] init];
    [self.cloudShare start];
}

- (void) updateCloudShareItem:(BranchCloudShareItem*)item {
    if (self.cloudShare == nil) self.cloudShare = [[BNCCloudShare alloc] init];
    [self.cloudShare updateItem:item];
}

@end

__attribute__((constructor))
void BNCForceBranchCloudShareToLoad(void) {
    // Force the category to load.
}
