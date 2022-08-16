/**
 @file          BNCDevice.Test.m
 @package       BranchTests
 @brief         Tests for BNCDevice.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCDevice.h"

@interface BNCDeviceTest : BNCTestCase
@end

@implementation BNCDeviceTest

- (void)testDevice {
    BNCDevice *device = [BNCDevice currentDevice];
    XCTAssertTrue(device.hardwareID.length > 0);
    XCTAssertTrue(
        [device.hardwareIDType isEqualToString:@"idfa"] ||
        [device.hardwareIDType isEqualToString:@"random"] ||
        [device.hardwareIDType isEqualToString:@"mac_address"]
    );
    XCTAssertFalse(device.deviceIsUnidentified);
    XCTAssertTrue([device.brandName isEqualToString:@"Apple"]);

    XCTAssertTrue([device.modelName hasPrefix:@"Mac"]);
    XCTAssertTrue([device.systemName isEqualToString:@"mac_OS"]);
    XCTAssertTrue(device.hardwareID.length > 0);

    XCTAssertTrue(
        device.systemVersion.doubleValue > 10.15 &&
        device.systemVersion.doubleValue <= 13
    );
    XCTAssertTrue(BNCTestStringMatchesRegex(device.systemBuildVersion, @"^[0-9A-Za-z]+$"));
    XCTAssertTrue(
        device.screenSize.height > 0 &&
        device.screenSize.width > 0
    );

    XCTAssertTrue(device.screenDPI >= 72.0 && device.screenDPI <= 216.0);

    // idfa is broken on 10.15+
    if ([self testDeviceSupportsIDFA]) {
        XCTAssertTrue(device.adTrackingIsEnabled);
        XCTAssertNotNil(device.advertisingID);
    } else {
        XCTAssertFalse(device.adTrackingIsEnabled);
        XCTAssertNil(device.advertisingID);
    }
    XCTAssertTrue([device.country isEqualToString:@"US"]);
    XCTAssertTrue([device.language isEqualToString:@"en"]);
    XCTAssertTrue(BNCTestStringMatchesRegex(device.localIPAddress, @"^\\d*\\.\\d*\\.\\d*\\.\\d*$"));
}

- (void)testIPAddresses {
    NSArray *d = [[BNCDevice currentDevice] allLocalIPAddresses];
    XCTAssertGreaterThan(d.count, 1);
    NSLog(@"IP Addresses: %@.", d);
}

@end
