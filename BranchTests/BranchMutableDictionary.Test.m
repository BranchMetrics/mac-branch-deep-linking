/**
 @file          BranchMutableDictionary.Test.m
 @package       BranchTests
 @brief         BranchMutableDictionary tests.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BranchMutableDictionary.h"

@interface BranchMutableDictionaryTest : BNCTestCase
@end

@implementation BranchMutableDictionaryTest

- (void)testDictionary {
    NSDictionary*truth = @{
        @"key1": @"value1",
        @"key2": @"value2",
        @"key3": @"value3"
    };

    BranchMutableDictionary *d = [[BranchMutableDictionary alloc] init];
    d[@"key1"] = @"value1";
    d[@"key2"] = @"value2";
    XCTAssertEqual(d.count, 2);
    [d setObject:@"value3" forKey:@"key3"];
    XCTAssertEqualObjects(d[@"key2"], @"value2");
    XCTAssertEqualObjects(d, truth);

    BranchMutableDictionary *c = [BranchMutableDictionary dictionaryWithDictionary:truth];
    XCTAssertTrue([c isKindOfClass:BranchMutableDictionary.class]);
    XCTAssertEqualObjects(c, truth);

    BranchMutableDictionary *e = [c copy];
    XCTAssertTrue([e isKindOfClass:BranchMutableDictionary.class]);
    XCTAssertEqualObjects(e, truth);
}

- (void) testCoding {
    NSDictionary*truth = @{
        @"key1": @"value1",
        @"key2": @"value2",
        @"key3": @"value3"
    };
    BranchMutableDictionary*d = [BranchMutableDictionary dictionaryWithDictionary:truth];
    NSData*data = [NSKeyedArchiver archivedDataWithRootObject:d];
    BranchMutableDictionary*e = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertTrue([e isKindOfClass:BranchMutableDictionary.class]);
    XCTAssertEqualObjects(e, truth);
}

@end
