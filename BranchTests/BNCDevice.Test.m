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

- (void) testDevice {
    BNCDevice *device = [BNCDevice currentDevice];
    XCTAssertTrue(device.hardwareID.length > 0);
    XCTAssertTrue(
        [device.hardwareIDType isEqualToString:@"vendor_id"] ||
        [device.hardwareIDType isEqualToString:@"random"]
    );
    XCTAssertFalse(device.deviceIsUnidentified);
    XCTAssertTrue([device.brandName isEqualToString:@"Apple"]);
    XCTAssertTrue([device.modelName hasPrefix:@"Mac"]);
    XCTAssertTrue([device.systemName isEqualToString:@"macOS"]);
    XCTAssertTrue(
        device.systemVersion.doubleValue > 10.0 &&
        device.systemVersion.doubleValue < 11.0
    );
    XCTAssertTrue(BNCTestStringMatchesRegex(device.systemBuildVersion, @"^[0-9A-F]*$"));
    XCTAssertTrue(
        device.screenSize.height > 0 &&
        device.screenSize.width > 0
    );
    XCTAssertTrue(device.screenDPI >= 72.0 && device.screenDPI <= 216.0);
    XCTAssertFalse(device.adTrackingIsEnabled);
    XCTAssertTrue(device.advertisingID == nil);
    XCTAssertTrue([device.country isEqualToString:@"US"]);
    XCTAssertTrue([device.language isEqualToString:@"en"]);
    XCTAssertTrue(device.browserUserAgent.length > 0);
    XCTAssertTrue(BNCTestStringMatchesRegex(device.localIPAddress, @"^\\d*\\.\\d*\\.\\d*\\.\\d*$"));
}

@end
