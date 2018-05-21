/**
 @file          BNCPersistenceTest.m
 @package       BranchTests
 @brief         < A brief description of the file function. >

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

- (void) testRemove {
    NSError *error = [BNCPersistence removeDataNamed:@"io.branch.sdk.test"];
    XCTAssertNil(error);
}

- (void) testSaveAndLoad {
    [BNCPersistence removeDataNamed:@"io.branch.sdk.test"];

    NSString*s = @"Howdy!";
    NSData*sd = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSError*error = [BNCPersistence saveDataNamed:@"io.branch.sdk.test" data:sd];
    XCTAssertNil(error);

    NSData*td = [BNCPersistence loadDataNamed:@"io.branch.sdk.test"];
    XCTAssertEqualObjects(sd, td);
}

@end
