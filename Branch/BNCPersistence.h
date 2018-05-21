//
/**
 @file          BNCPersistence.h
 @package       Branch
 @brief         < A brief description of the file function. >

 @author        Edward
 @date          2018
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
@end

NS_ASSUME_NONNULL_END
