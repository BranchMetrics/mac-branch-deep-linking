/**
 @file          BranchSession.h
 @package       Branch
 @brief         Attributes of the current Branch session.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchLinkProperties.h"
#import "BranchUniversalObject.h"

NS_ASSUME_NONNULL_BEGIN


#ifndef BranchSession_h
#define BranchSession_h
/**
    Branch session parameters.
*/
@interface BranchSession : NSObject

+ (instancetype) sessionWithDictionary:(NSDictionary*)dictionary;

@property (nonatomic, strong) NSString*_Nullable sessionID;
@property (nonatomic, assign) BOOL isFirstSession;
@property (nonatomic, assign) BOOL isBranchURL;
@property (nonatomic, assign, readonly) BOOL matchGuaranteed;
@property (nonatomic, strong, readonly) NSDate* clickTimestamp;
@property (nonatomic, strong) NSURL*_Nullable referringURL;
@property (nonatomic, strong) NSString*_Nullable randomizedBundleToken;
@property (nonatomic, strong) NSString*_Nullable userIdentityForDeveloper;
@property (nonatomic, strong) NSString*_Nullable randomizedDeviceToken;
@property (nonatomic, strong) NSString*_Nullable linkCreationURL;
@property (nonatomic, strong) BranchUniversalObject*_Nullable linkContent;
@property (nonatomic, strong) BranchLinkProperties*_Nullable linkProperties;
@property (nonatomic, strong) NSDictionary*_Nullable data;
@end

#endif

NS_ASSUME_NONNULL_END
