/**
 @file          BranchCommerce.Test.m
 @package       BranchTests
 @brief         BranchCommerce Tests

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BranchCommerce.h"

@interface BranchCommerceTest : BNCTestCase
@end

@implementation BranchCommerceTest

- (void)testBranchCommerce {
    XCTAssertTrue(BNCProductCategoryAllCategories().count == 21);
    XCTAssertTrue(BNCCurrencyAllCurrencies().count == 178);
}

@end
