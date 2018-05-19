/**
 @file          BNCEncoder.h
 @package       Branch
 @brief         < A brief description of the file function. >

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCEncoder : NSObject

+ (NSError*_Nullable) decodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars;

+ (NSError*_Nullable) encodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars;

@end

NS_ASSUME_NONNULL_END
