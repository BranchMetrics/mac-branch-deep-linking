/**
 @file          BranchSession.h
 @package       Branch-SDK
 @brief         Session parameters.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchLinkProperties.h"
#import "BranchUniversalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchSession : NSObject

+ (instancetype) sessionWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) dictionary;

@property (nonatomic, strong) NSString*_Nullable sessionID;
@property (nonatomic, assign) BOOL isFirstSession;
@property (nonatomic, assign) BOOL isBranchURL;
@property (nonatomic, strong) NSURL*_Nullable referringURL;
@property (nonatomic, strong) NSString*_Nullable identityID;
@property (nonatomic, strong) NSString*_Nullable developerIdentityForUser;
@property (nonatomic, strong) NSString*_Nullable deviceFingerprintID;
@property (nonatomic, strong) BranchUniversalObject*_Nullable linkContent;
@property (nonatomic, strong) BranchLinkProperties*_Nullable linkProperties;
@property (nonatomic, strong) NSDictionary*_Nullable data;
@end

NS_ASSUME_NONNULL_END
