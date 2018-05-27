/**
 @file          BranchLinkProperties.h
 @package       Branch-SDK
 @brief         Branch link properties: non-content properties that are associated with a link.

 @author        Derrick Staten
 @date          October 2015
 @copyright     Copyright © 2015 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchLinkProperties : NSObject

+ (instancetype)linkPropertiesWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) dictionary;

@property (nonatomic, strong) NSArray<NSString*>*_Nullable  tags;
@property (nonatomic, strong) NSString*_Nullable feature;
@property (nonatomic, strong) NSString*_Nullable alias;
@property (nonatomic, strong) NSString*_Nullable channel;
@property (nonatomic, strong) NSString*_Nullable stage;
@property (nonatomic, strong) NSString*_Nullable campaign;
@property (nonatomic, assign) NSUInteger matchDuration;
@property (nonatomic, strong, null_resettable) NSMutableDictionary* controlParams;
@end

NS_ASSUME_NONNULL_END
