/**
 @file          Branch.Test.m
 @package       BranchTests
 @brief         Branch frame work tests.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "Branch.h"

@interface BranchTest : BNCTestCase
@end

@implementation BranchTest

- (void)testVersion {
    double vn = BranchVersionNumber;
    const unsigned char *vs = BranchVersionString;
    XCTAssertTrue(vn > 0 && vs);
    NSString*testString = [[NSString alloc] initWithUTF8String:(const char*)vs];
    XCTAssertTrue([testString hasPrefix:@"@(#)PROGRAM:Branch  PROJECT:Branch-"]);
}

@end
