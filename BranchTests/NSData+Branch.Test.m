/**
 @file          NSData+Branch.Test.m
 @package       BranchTests
 @brief         Tests for the NSData+Branch category.

 @author        Edward Smith
 @date          June 10, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "NSData+Branch.h"

@interface NSDataBranchTest : BNCTestCase
@end

@implementation NSDataBranchTest

- (void) testHexDecode {
    char bytes[] = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    NSData*truthData = [NSData dataWithBytes:bytes length:8];
    NSData*data = [NSData bnc_dataWithHexString:@"0123456789abcdef"];
    XCTAssertEqualObjects(truthData, data);

    data = [NSData bnc_dataWithHexString:@"0123456789ABCDEF"];
    XCTAssertEqualObjects(truthData, data);
}

- (void) testHexDecodeOddBytes {
    char bytes[] = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xe0 };
    NSData*truthData = [NSData dataWithBytes:bytes length:8];
    NSData*data = [NSData bnc_dataWithHexString:@"0123456789abcde"];
    XCTAssertEqualObjects(truthData, data);
}

- (void) testHexDecodeTricky {
    char bytes[] = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    NSData*truthData = [NSData dataWithBytes:bytes length:8];

    NSData*data = [NSData bnc_dataWithHexString:@""];
    XCTAssertTrue(data != nil && data.length == 0);

    data = [NSData bnc_dataWithHexString:@" XXX 012345678 9ab cde\nf"];
    XCTAssertEqualObjects(truthData, data);
}

- (void) testHighLowBytes {
    char bytes[] = { 0x00, 0x01, 0x7f, 0x80, 0xff };
    NSData*truthData = [NSData dataWithBytes:bytes length:5];
    NSData*data = [NSData bnc_dataWithHexString:@"0001 7f80 ff"];
    XCTAssertEqualObjects(truthData, data);
}

@end
