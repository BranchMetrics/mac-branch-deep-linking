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
#import "BNCThreads.h"
#import "BNCEncoder.h"
#import "BNCLog.h"

NSString*const BranchCloundShareNotification;
NSString*const BranchCloundShareItemKey;

static NSString*const BranchCloudShareKey = @"io.branch.sdk.CloudShare";
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
- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (void) start;
- (void) updateItem:(BranchCloudShareItem*)item;

@property (strong) NSUbiquitousKeyValueStore*cloudStore;
@property (strong) BranchCloudShareItem*cloudShareItem;
@property (strong) NSUserActivity*userActivity;
@property (strong) NSDate*lastUpdateDate;
@end

@implementation BNCCloudShare

- (instancetype) init {
    self = [super init];
    return self;
}

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
    [self.cloudStore synchronize];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateItem:(BranchCloudShareItem *)item {
    item.updateDate = [NSDate date];
    self.cloudShareItem = item;
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
    if (![updatedKeys containsObject:BranchCloudShareDateKey]) return;

    NSDate*updateDate = [self.cloudStore objectForKey:BranchCloudShareDateKey];
    NSData*itemData = [self.cloudStore objectForKey:BranchCloudShareKey];
    if (updateDate == nil || itemData == nil) return;

    if (self.lastUpdateDate != nil && [updateDate compare:self.lastUpdateDate] < 0)
        return;

    BranchCloudShareItem*item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
    if (!item) return;

    self.cloudShareItem = item;
    self.lastUpdateDate = [NSDate date];

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
