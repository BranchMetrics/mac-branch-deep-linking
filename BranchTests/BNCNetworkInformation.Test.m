/**
 @file          BNCNetworkInformation.Test.m
 @package       BranchTests
 @brief         Tests for BNCNetworkInformation.

 @author        Edward Smith
 @date          August 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCNetworkInformation.h"

@interface BNCNetworkInformationTest : BNCTestCase
@end

@implementation BNCNetworkInformationTest

- (void)testAreaEntries {
    NSArray*entries = [BNCNetworkInformation areaEntries];
    XCTAssertGreaterThan(entries.count, 0);
    NSLog(@"%@", entries);
}

- (void)testCurrentInterfaces {
    NSArray*entries = [BNCNetworkInformation currentInterfaces];
    XCTAssertGreaterThan(entries.count, 0);
    NSLog(@"%@", entries);
}

- (void)testLocal {
    BNCNetworkInformation*entry = [BNCNetworkInformation local];
    XCTAssertGreaterThan(entry.interface.length, 0);
    XCTAssertGreaterThan(entry.address.length, 0);
    XCTAssertGreaterThan(entry.displayAddress.length, 0);
    XCTAssertGreaterThan(entry.inetAddress.length, 0);
    XCTAssertGreaterThan(entry.displayInetAddress.length, 0);
    XCTAssertGreaterThan(entry.inetAddressType, 0);
    NSLog(@"%@", entry);
}

@end
