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

FOUNDATION_EXTERN NSData*_Nullable BNCPersistenceLoadDataNamed(NSString*name);
FOUNDATION_EXTERN void BNCPersistenceSaveDataNamed(NSString*name, NSData*data);

@interface BNCSettings : NSObject <NSSecureCoding>
+ (instancetype) sharedInstance;
- (void) save;
@property (atomic, strong) NSString*_Nullable   deviceFingerprintID;
@property (atomic, strong) NSString*_Nullable   identityID;
@property (atomic, strong) NSString*_Nullable   developerIdentityForUser;
@property (atomic, strong) NSString*_Nullable   sessionID;
@property (atomic, strong) NSString*_Nullable   linkCreationURL;
@property (atomic, assign) BOOL                 limitFacebookTracking;
@property (atomic, strong) NSMutableDictionary<NSString*, NSString*> *requestMetadataDictionary;
@property (atomic, strong) NSMutableDictionary<NSString*, NSString*> *instrumentationDictionary;
@end

NS_ASSUME_NONNULL_END
