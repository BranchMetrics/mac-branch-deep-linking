/**
 @file          BNCSettings.h
 @package       Branch
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchMutableDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCSettings : NSObject <NSSecureCoding>
+ (instancetype) loadSettings;
- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (void) clearAllSettings;
- (void) clearUserIdentifyingInformation;
- (void) setNeedsSave;
- (void) save;
@property (atomic, copy)   void (^_Nullable settingsSavedBlock)(BNCSettings*settings, NSError*_Nullable error);
@property (atomic, copy)   NSString*_Nullable   randomizedDeviceToken;
@property (atomic, copy)   NSString*_Nullable   randomizedBundleToken;
@property (atomic, copy)   NSString*_Nullable   deviceFingerprintID;
@property (atomic, copy)   NSString*_Nullable   identityID;
@property (atomic, copy)   NSString*_Nullable   userIdentityForDeveloper;
@property (atomic, copy)   NSString*_Nullable   sessionID;
@property (atomic, copy)   NSString*_Nullable   linkCreationURL;
@property (atomic, assign) BOOL                 limitFacebookTracking;
@property (atomic, assign) BOOL                 userTrackingDisabled;

// URL Black list settings:

@property (atomic, assign) NSInteger            URLBlackListVersion;
@property (atomic, copy) NSDate*_Nullable       URLBlackListLastRefreshDate;
@property (atomic, copy) NSArray<NSString*>*_Nullable URLBlackList;

@property (atomic, strong, null_resettable)
    BranchMutableDictionary<NSString*, NSString*> *requestMetadataDictionary;
@property (atomic, strong, null_resettable)
    BranchMutableDictionary<NSString*, NSString*> *instrumentationDictionary;

@end

NS_ASSUME_NONNULL_END
