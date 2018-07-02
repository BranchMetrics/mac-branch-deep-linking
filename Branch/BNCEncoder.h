/**
 @file          BNCEncoder.h
 @package       Branch
 @brief         A light weight, general purpose object encoder.

 @author        Edward Smith
 @date          June 2018
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

+ (NSError*) copyInstance:(id)toInstance
        fromInstance:(id)fromInstance
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray;

@end

NS_ASSUME_NONNULL_END
