/**
 @file          NSData+Branch.h
 @package       Branch
 @brief         < A brief description of the file function. >

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

@interface NSData (Branch)
+ (NSData*) bnc_dataWithHexString:(NSString*)string;
@end

FOUNDATION_EXPORT void BNCForceNSDataCategoryToLoad(void)
    __attribute__((constructor));
