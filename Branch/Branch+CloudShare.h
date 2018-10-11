/**
 @file          Branch+CloudShare.h
 @package       Branch
 @brief         Share Branch links in the cloud. Useful for tvOS.

 @author        Edward Smith
 @date          October 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "BranchMainClass.h"

// TODO: This is super experimental.

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString*const BranchCloundShareNotification;
FOUNDATION_EXTERN NSString*const BranchCloundShareItemKey;

@interface BranchCloudShareItem : NSObject <NSSecureCoding>
@property (strong) NSString*activityID;
@property (strong) NSString*contentTitle;
@property (strong) NSString*contentDescription;
@property (strong) NSSet*contentKeywords;
@property (strong) NSURL*contentURL;
@property (strong) NSString*originatingApplicationName;
@property (strong) NSDate*updateDate;
@end


@interface Branch (BranchCloudShare)
- (void) startCloudShareNotifications;
- (void) updateCloudShareItem:(BranchCloudShareItem*)item;
@end

FOUNDATION_EXPORT void BNCForceBranchCloudShareToLoad(void)
    __attribute__((constructor));

NS_ASSUME_NONNULL_END
