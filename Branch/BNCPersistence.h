/**
 @file          BNCPersistence.h
 @package       Branch
 @brief         Persists a smallish (< 1mb?) set of data between app runs.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

/**
  @brief        Returns a URL appropriate for storing persistent settings that aren't normally user visible.
  @discussion   This URL is defined as a function so it can be called before the class system are loaded and
                initialized.
  @return       Returns a file system URL.
 */
NSURL* BNCURLForBranchDataDirectory(void);

@interface BNCPersistence : NSObject
+ (NSData*_Nullable) loadDataNamed:(NSString*)name;
+ (NSError*_Nullable) saveDataNamed:(NSString*)name data:(NSData*)data;
+ (NSError*_Nullable) removeDataNamed:(NSString*)name;

+ (id _Nullable) unarchiveObjectNamed:(NSString*)name;
+ (NSError*_Nullable) archiveObject:(id<NSSecureCoding>)object named:(NSString*)name;
@end

NS_ASSUME_NONNULL_END
