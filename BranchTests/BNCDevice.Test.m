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
        [device.hardwareIDType isEqualToString:@"idfa"] ||
        [device.hardwareIDType isEqualToString:@"vendor_id"] ||
        [device.hardwareIDType isEqualToString:@"random"] ||
        [device.hardwareIDType isEqualToString:@"net_address"]
    );
    XCTAssertFalse(device.deviceIsUnidentified);
    XCTAssertTrue([device.brandName isEqualToString:@"Apple"]);

#if TARGET_OS_OSX

    XCTAssertTrue([device.modelName hasPrefix:@"Mac"]);
    XCTAssertTrue([device.systemName isEqualToString:@"mac_OS"]);

#elif TARGET_OS_TV

    XCTAssertTrue([device.modelName hasPrefix:@"Mac"]);
    XCTAssertTrue([device.systemName isEqualToString:@"tv_OS"]);

#elif TARGET_OS_IOS

    XCTAssertTrue([device.modelName hasPrefix:@"Mac"]);
    XCTAssertTrue([device.systemName isEqualToString:@"iOS"]);

#else

    #error Unknown target.

#endif

    XCTAssertTrue(
        device.systemVersion.doubleValue > 8.0 &&
        device.systemVersion.doubleValue <= 11.0
    );
    XCTAssertTrue(BNCTestStringMatchesRegex(device.systemBuildVersion, @"^[0-9A-F]*$"));
    XCTAssertTrue(
        device.screenSize.height > 0 &&
        device.screenSize.width > 0
    );

#if TARGET_OS_OSX
    XCTAssertTrue(device.screenDPI >= 72.0 && device.screenDPI <= 216.0);
#else
    XCTAssertTrue(device.screenDPI >= 1.0 && device.screenDPI <= 3.0);
#endif

    XCTAssertFalse(device.adTrackingIsEnabled);
    XCTAssertTrue(device.advertisingID == nil);
    XCTAssertTrue([device.country isEqualToString:@"US"]);
    XCTAssertTrue([device.language isEqualToString:@"en"]);
    XCTAssertTrue(device.browserUserAgent.length > 0);
    XCTAssertTrue(BNCTestStringMatchesRegex(device.localIPAddress, @"^\\d*\\.\\d*\\.\\d*\\.\\d*$"));
}

@end
