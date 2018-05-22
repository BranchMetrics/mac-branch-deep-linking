/**
 @file          BNCSettings.Test.m
 @package       BranchTests
 @brief         Tests for BNCSettings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCSettings.h"
#import <objc/runtime.h>

@interface BNCSettingsTest : BNCTestCase
@end

@implementation BNCSettingsTest

- (void) testSettingsTriggerSave {
    __block XCTestExpectation*expectation = [self expectationWithDescription:@"testSettingsSave"];

    BNCSettings*settings = [[BNCSettings alloc] init];
    settings.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        [expectation fulfill];
    };
    settings.limitFacebookTracking = YES;
    [self awaitExpectations];

    [self resetExpectations];
    expectation = [self expectationWithDescription:@"testSettingsSaveDictionary"];
    settings.instrumentationDictionary[@"howdy"] = @"partner";
    [self awaitExpectations];
}

- (void) testSettingsSaveAndLoad {
    BNCSettings*s = [[BNCSettings alloc] init];
    s.deviceFingerprintID = @"fid";
    s.linkCreationURL = @"lcu";
    s.limitFacebookTracking = YES;
    s.instrumentationDictionary[@"key"] = @"value";
    [s save];

    BNCSettings*t = [BNCSettings loadSettings];
    XCTAssertTrue([t isKindOfClass:[BNCSettings class]]);
    XCTAssertEqualObjects(s.deviceFingerprintID, t.deviceFingerprintID);
    XCTAssertEqualObjects(s.linkCreationURL, t.linkCreationURL);
    XCTAssertEqual(s.limitFacebookTracking, t.limitFacebookTracking);
    XCTAssertEqualObjects(s.instrumentationDictionary, t.instrumentationDictionary);

    // Make sure auto-save is triggered on new object:
    __block XCTestExpectation*expectation = [self expectationWithDescription:@"testSettingsSave"];
    t.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        [expectation fulfill];
    };
    t.limitFacebookTracking = YES;
    [self awaitExpectations];
}

- (void) testSettingsDetectRace {
    __block int count = 0;
    __block XCTestExpectation*expectation = [self expectationWithDescription:@"testSettingsDetectRace"];
    BNCSettings*s = [[BNCSettings alloc] init];
    s.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        count++;
        if (count > 1) {
            [expectation fulfill];
            expectation = nil;
        } else {
            BNCSleepForTimeInterval(0.5);
        }
    };
    BNCSleepForTimeInterval(1.1);
    s.limitFacebookTracking = YES;
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue(count > 1);
}

- (void) testProxy {
    BNCSettings*settings = [[BNCSettings alloc] init];
    Class proxyClass = NSClassFromString(@"BNCSettingsProxy");
    XCTAssertTrue((__bridge void*) settings.class == (__bridge void*) proxyClass);

    Ivar realSettingsIvar = class_getInstanceVariable(proxyClass, "_settings");
    BNCSettings*realSettings = object_getIvar(settings, realSettingsIvar);
    XCTAssertNotNil(realSettings);
    XCTAssertTrue((__bridge void*) realSettings.class == (__bridge void*) BNCSettings.class);
}

- (void) testSharedInstance {
    BNCSettings*settings = [BNCSettings sharedInstance];
    XCTAssertTrue([settings isKindOfClass:[BNCSettings class]]);
    XCTAssertTrue([settings isProxy]);
    Class settingsClass = [settings class];
    Class proxyClass = NSClassFromString(@"BNCSettingsProxy");
    XCTAssertTrue((__bridge void*) settingsClass == (__bridge void*) proxyClass);
    NSString*fpid = settings.deviceFingerprintID; // Make sure that
    XCTAssertTrue(fpid == nil || fpid != nil);
}

@end
