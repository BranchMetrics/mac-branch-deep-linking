/**
 @file          UIViewController+Branch.Test.m
 @package       BranchTests
 @brief         Tests for the UIViewController+Branch category.

 @author        Edward Smith
 @date          August 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "UIViewController+Branch.h"

@interface UIViewControllerBranchTest : BNCTestCase
@end

@implementation UIViewControllerBranchTest

#if TARGET_OS_OSX

- (void) testMacMethods {
}

#else

- (void) testMethods {
    XCTAssertNotNil([UIViewController bnc_currentWindow]);
    UIViewController*vc = [UIViewController bnc_currentViewController];
    XCTAssertNotNil(vc);
    XCTAssertNotNil([vc bnc_currentViewController]);
}

#endif

@end
