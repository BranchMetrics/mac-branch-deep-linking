/**
 @file          BNCPersistenceTest.m
 @package       BranchTests
 @brief         Tests for BNCPersistence.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCPersistence.h"

@interface BNCPersistenceTest : BNCTestCase
@end

@implementation BNCPersistenceTest

- (void) testBranchDirectory {
    NSURL* url = BNCURLForBranchDataDirectory();
    XCTAssertNotNil(url);
}

- (void) testSaveLoadRemove {
    BNCPersistence*persistence = [[BNCPersistence alloc] initWithAppGroup:@"io.branch.sdk.unit.tests"];
    [persistence removeDataNamed:@"io.branch.sdk.test"];

    NSString*s = @"Howdy!";
    NSData*sd = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSError*error = [persistence saveDataNamed:@"io.branch.sdk.test" data:sd];
    XCTAssertNil(error);

    NSData*td = [persistence loadDataNamed:@"io.branch.sdk.test"];
    XCTAssertEqualObjects(sd, td);

    error = [persistence removeDataNamed:@"io.branch.sdk.test"];
    XCTAssertNil(error);

    td = [persistence loadDataNamed:@"io.branch.sdk.test"];
    XCTAssertNil(td);
}

@end
