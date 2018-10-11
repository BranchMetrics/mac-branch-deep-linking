/**
 @file          BNCEncoder.m
 @package       Branch
 @brief         A light weight, general purpose object encoder.

 @author        Edward
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCEncoder.h"
#import "BNCLog.h"
#import <objc/runtime.h>

@implementation BNCEncoder

+ (NSError*_Nullable) decodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray {

    NSSet*ignoreIvars = nil;
    if (ignoreIvarsArray)
        ignoreIvars = [NSSet setWithArray:ignoreIvarsArray];

    uint count = 0;
    Class class = [instance class];
    Ivar *ivars = class_copyIvarList(class, &count);
    for (uint i = 0; i < count; ++i) {
        Ivar ivar = ivars[i];
        const char* encoding = ivar_getTypeEncoding(ivars[i]);
        const char* ivarName = ivar_getName(ivars[i]);
        void* ivarPtr = nil;
        if (class == instance) {
            //  instance is a class, so there aren't any ivar values.
        } else if (encoding[0] == '@' || encoding[0] == '#') {
            ivarPtr = (__bridge void*) object_getIvar(instance, ivars[i]);
        } else {
            ivarPtr = (void*) (((__bridge void*)instance) + ivar_getOffset(ivars[i]));
        }

        #define isTypeOf(type) \
            (strncmp(encoding, @encode(type), strlen(encoding)) == 0)

        NSString*key = [NSString stringWithFormat:@"%s", ivarName];
        if ([ignoreIvars containsObject:key])
            continue;

        if (encoding[0] == '@') {
            NSString *className = [NSString stringWithFormat:@"%s", encoding];
            if ([className hasPrefix:@"@\""])
                className = [className substringFromIndex:2];
            if ([className hasSuffix:@"\""])
                className = [className substringToIndex:className.length-1];
            id value = [coder decodeObjectOfClass:NSClassFromString(className) forKey:key];
            object_setIvar(instance, ivar, value);
        }
        else if (isTypeOf(BOOL)) {
            *((BOOL*)ivarPtr) = [coder decodeBoolForKey:key];
        }
        else if (isTypeOf(NSInteger)) {
            *((NSInteger*)ivarPtr) = [coder decodeIntegerForKey:key];
        }
        else if (isTypeOf(CGFloat)) {
            *((CGFloat*)ivarPtr) = [coder decodeFloatForKey:key];
        }
        else if (isTypeOf(double)) {
            *((double*)ivarPtr) = [coder decodeDoubleForKey:key];
        }
        else {
            NSString*message = [NSString stringWithFormat:
                @"Couldn't decode '%s' type '%s'.", ivarName, encoding];
            BNCLogError(@"%@", message);
            NSError*error = [NSError errorWithDomain:NSCocoaErrorDomain
                code:NSFormattingError userInfo:@{ NSLocalizedDescriptionKey: message }];
            return error;
        }
    }
    if (ivars) free(ivars);
    return nil;
}

+ (NSError*_Nullable) encodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray {

    NSSet*ignoreIvars = nil;
    if (ignoreIvarsArray)
        ignoreIvars = [NSSet setWithArray:ignoreIvarsArray];

    uint count = 0;
    Class class = [instance class];
    Ivar *ivars = class_copyIvarList(class, &count);
    for (uint i = 0; i < count; ++i) {
        const char* encoding = ivar_getTypeEncoding(ivars[i]);
        const char* ivarName = ivar_getName(ivars[i]);
        const void* ivarPtr = nil;
        if (class == instance) {
            //  instance is a class, so there aren't any ivar values.
        } else if (encoding[0] == '@' || encoding[0] == '#') {
            ivarPtr = (__bridge void*) object_getIvar(instance, ivars[i]);
        } else {
            ivarPtr = (void*) (((__bridge void*)instance) + ivar_getOffset(ivars[i]));
        }

        #define isTypeOf(type) \
            (strncmp(encoding, @encode(type), strlen(encoding)) == 0)

        NSString*key = [NSString stringWithFormat:@"%s", ivarName];
        if ([ignoreIvars containsObject:key])
            continue;

        if (encoding[0] == '@') {
            [coder encodeObject:(__bridge id<NSObject>)ivarPtr forKey:key];
        }
        else if (ivarPtr == NULL) {
            continue;
        }
        else if (isTypeOf(BOOL)) {
            [coder encodeBool:*((BOOL*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(NSInteger)) {
            [coder encodeInteger:*((NSInteger*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(CGFloat)) {
            [coder encodeFloat:*((CGFloat*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(double)) {
            [coder encodeDouble:*((double*)ivarPtr) forKey:key];
        }
        else {
            NSString*message = [NSString stringWithFormat:
                @"Couldn't decode '%s' type '%s'.", ivarName, encoding];
            BNCLogError(@"%@", message);
            NSError*error = [NSError errorWithDomain:NSCocoaErrorDomain
                code:NSFormattingError userInfo:@{ NSLocalizedDescriptionKey: message }];
            return error;
        }
    }
    if (ivars) free(ivars);
    return nil;
}

+ (NSError*) copyInstance:(id)toInstance
         fromInstance:(id)fromInstance
             ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray {
    NSError*error = nil;
    @try {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSMutableData*data = [[NSMutableData alloc] init];
        NSKeyedArchiver*archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [BNCEncoder encodeInstance:fromInstance withCoder:archiver ignoring:ignoreIvarsArray];
        [archiver finishEncoding];
        NSKeyedUnarchiver*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        unarchiver.requiresSecureCoding = YES;
        [BNCEncoder decodeInstance:toInstance withCoder:unarchiver ignoring:ignoreIvarsArray];
        #pragma clang diagnostic pop
    }
    @catch (id e) {
        NSString*message = [NSString stringWithFormat:@"Can't copy '%@': %@.", fromInstance, e];
        BNCLogError(@"%@", message);
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
    }
    return error;
}

@end
