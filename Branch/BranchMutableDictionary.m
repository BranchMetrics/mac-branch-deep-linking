/**
 @file          BranchMutableDictionary.m
 @package       Branch
 @brief         A thread-safe mutable dictionary.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchMutableDictionary.h"

@interface BranchMutableDictionary () {
    NSMutableDictionary *_dictionary;
}
@end

@implementation BranchMutableDictionary

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    _dictionary = [[NSMutableDictionary alloc] init];
    return self;
}

- (instancetype) initWithCapacity:(NSUInteger)numItems {
    self = [super init];
    if (!self) return self;
    _dictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    _dictionary = [[NSMutableDictionary alloc] initWithCoder:aDecoder];
    return self;
}

- (instancetype) copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (instancetype) mutableCopyWithZone:(NSZone *)zone {
    @synchronized(self) {
        BranchMutableDictionary*copy = [[BranchMutableDictionary allocWithZone:zone] init];
        [copy setDictionary:self];
        return copy;
    }
}

- (NSUInteger) count {
    @synchronized(self) {
        return [_dictionary count];
    }
}

- (id)objectForKey:(id)aKey {
    @synchronized(self) {
        return (aKey) ? [_dictionary objectForKey:aKey] : nil;
    }
}

- (NSEnumerator *)keyEnumerator {
    @synchronized(self) {
        return [_dictionary keyEnumerator];
    }
}

- (void) setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    @synchronized(self) {
        if (aKey == nil) {
        } else
        if (anObject == nil)
            [_dictionary removeObjectForKey:aKey];
        else
            [_dictionary setObject:anObject forKey:aKey];
    }
}

- (void) removeObjectForKey:(id)aKey {
    @synchronized(self) {
        if (aKey != nil) [_dictionary removeObjectForKey:aKey];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    @synchronized(self) {
        [_dictionary encodeWithCoder:aCoder];
    }
}

- (Class) classForCoder {
    return self.class;
}

@end
