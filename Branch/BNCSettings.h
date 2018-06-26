/**
 @file          BNCSettings.h
 @package       Branch-SDK
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCSettings : NSObject <NSSecureCoding>
//+ (instancetype) sharedInstance;
+ (instancetype) loadSettings;
- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (void) clearAllSettings;
- (void) clearTrackingInformation;
- (void) setNeedsSave;
- (void) save;
@property (atomic, copy)   void (^_Nullable settingsSavedBlock)(BNCSettings*settings, NSError*_Nullable error);
@property (atomic, copy)   NSString*_Nullable   deviceFingerprintID;
@property (atomic, copy)   NSString*_Nullable   identityID;
@property (atomic, copy)   NSString*_Nullable   userIdentityForDeveloper;
@property (atomic, copy)   NSString*_Nullable   sessionID;
@property (atomic, copy)   NSString*_Nullable   linkCreationURL;
@property (atomic, assign) BOOL                 limitFacebookTracking;
@property (atomic, assign) BOOL                 trackingDisabled;

// URL Black list settings:

@property (atomic, assign) NSInteger            URLBlackListVersion;
@property (atomic, copy) NSDate*_Nullable       URLBlackListLastRefreshDate;
@property (atomic, copy) NSArray<NSString*>*_Nullable URLBlackList;

@property (atomic, strong, null_resettable)
    NSMutableDictionary<NSString*, NSString*> *requestMetadataDictionary;
@property (atomic, strong, null_resettable)
    NSMutableDictionary<NSString*, NSString*> *instrumentationDictionary;

@end

NS_ASSUME_NONNULL_END
