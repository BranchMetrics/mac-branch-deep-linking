/**
 @file          NSString+Branch.h
 @package       Branch
 @brief         NSString Additions

 @author        Edward Smith
 @date          February 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Branch)

/**
 Compares the receiver to a masked string.  Masked characters (the '*' character) are
 ignored for purposes of the compare.

 @return YES if string (ignoring any masked characters) is equal to the receiver.
*/
- (BOOL) bnc_isEqualToMaskedString:(NSString*_Nullable)string;

/** @return Returns a string that is truncated at the first null character. */
- (NSString*) bnc_stringTruncatedAtNull;

/**
 The `containsString:` method isn't supported pre-iOS 8.  Here we roll our own.

 @param string    The string to for comparison.

 @return Reurns true if the instance contains the string.
*/
- (BOOL) bnc_containsString:(NSString*_Nullable)string;
@end

FOUNDATION_EXPORT void BNCForceNSStringCategoryToLoad(void)
    __attribute__((constructor));

NS_ASSUME_NONNULL_END
