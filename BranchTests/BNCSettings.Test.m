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
#import <stdatomic.h> // import not available in Xcode 7

@interface BNCSettingsTest : BNCTestCase
@end

@implementation BNCSettingsTest

- (void) testSettingsTriggerSave {
    BNCSettings*settings = [[BNCSettings alloc] init];
    XCTestExpectation*expectationClear = [self expectationWithDescription:@"testSettingsClear"];
    settings.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        XCTAssertNotNil(settings);
        XCTAssertNil(error);
        XCTAssertEqual(settings.limitFacebookTracking, NO);
        XCTAssertEqualObjects(settings.identityID, nil);
        [expectationClear fulfill];
    };
    [settings clearAllSettings];
    [self awaitExpectations];
    [self resetExpectations];

    XCTestExpectation*expectationSave = [self expectationWithDescription:@"testSettingsSave"];
    settings.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        XCTAssertNotNil(settings);
        XCTAssertNil(error);
        XCTAssertEqual(settings.limitFacebookTracking, YES);
        XCTAssertEqualObjects(settings.identityID, @"12345");
        [expectationSave fulfill];
    };
    settings.limitFacebookTracking = YES;
    settings.identityID = @"12345";
    [self awaitExpectations];
    settings.settingsSavedBlock = nil;
}

- (void) testSaveDictionary {
    BNCSettings*settings = [[BNCSettings alloc] init];
    [settings clearAllSettings];
    XCTestExpectation*expectation = [self expectationWithDescription:@"testSaveDictionary"];
    settings.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        XCTAssertNotNil(settings);
        XCTAssertNil(error);
        XCTAssertEqualObjects(settings.instrumentationDictionary, @{@"howdy":@"partner"});
        [expectation fulfill];
    };
    settings.instrumentationDictionary[@"howdy"] = @"partner";
    [self awaitExpectations];
    settings.settingsSavedBlock = nil;
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

    // Make sure auto-save is triggered on the new settings object:
    __block XCTestExpectation*expectation = [self expectationWithDescription:@"testSettingsSave"];
    t.settingsSavedBlock = ^ (BNCSettings*settings, NSError*_Nullable error) {
        [expectation fulfill];
    };
    t.limitFacebookTracking = NO;
    [self awaitExpectations];
    t.settingsSavedBlock = nil;
}

- (void) testSettingsDetectRaceAndFrequency {
    __block _Atomic(long) count = 0;
    BNCSettings*s = [[BNCSettings alloc] init];
    s.settingsSavedBlock = ^ (BNCSettings*_Nonnull settings, NSError*error) {
        atomic_fetch_add(&count, 1);
        NSLog(@"Count: %ld.", count);
    };
    BNCSleepForTimeInterval(1.5);
    XCTAssertEqual(atomic_load(&count), 0);
    s.limitFacebookTracking = YES;
    BNCSleepForTimeInterval(5.0);
    XCTAssertEqual(atomic_load(&count), 1);
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

/*  Try not to have a shared instance.
    
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
*/

@end
