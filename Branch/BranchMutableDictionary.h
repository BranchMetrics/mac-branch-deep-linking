/**
 @file          BranchMutableDictionary.h
 @package       Branch
 @brief         A thread-safe mutable dictionary.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>


#ifndef BranchMutableDictionary_h
#define BranchMutableDictionary_h

/**
 This is a thread-safe version of an NSMutableDictionary.
 */
@interface BranchMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithCapacity:(NSUInteger)numItems NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
@end

#endif
