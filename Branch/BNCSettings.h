/**
 @file          BNCSettings.h
 @package       Branch-SDK
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

@interface BNCSettings : NSObject
+ (instancetype) sharedInstance;
@property (atomic, strong) NSString*_Nullable   deviceFingerprintID;
@property (atomic, strong) NSString*_Nullable   identityID;
@property (atomic, strong) NSString*_Nullable   developerIdentityForUser;
@property (atomic, assign) BOOL                 limitFacebookTracking;
@end
