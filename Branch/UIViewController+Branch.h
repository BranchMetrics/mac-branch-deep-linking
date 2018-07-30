/**
 @file          UIViewController+Branch.h
 @package       Branch
 @brief         UIViewController Additions

 @author        Edward Smith
 @date          November 16, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN
#if TARGET_OS_TV || TARGET_OS_IOS

@interface UIViewController (Branch)
+ (UIWindow*_Nullable) bnc_currentWindow;
+ (UIViewController*_Nullable) bnc_currentViewController;
- (UIViewController*_Nonnull)  bnc_currentViewController;
@end

#endif
void BNCForceUIViewControllerCategoryToLoad(void) __attribute__((constructor));
NS_ASSUME_NONNULL_END
