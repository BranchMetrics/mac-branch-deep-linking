/**
 @file          BNCKeyChain.Test.m
 @package       Branch-SDK-Tests
 @brief         BNCKeyChain tests.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCKeyChain.h"
#import "BNCApplication+BNCTest.h"
#import "BNCDevice.h"

@interface BNCKeyChainTest : BNCTestCase
@end

@implementation BNCKeyChainTest

- (void)testKeyChain {
    NSError *error = nil;
    NSString*value = nil;
    NSArray *array, *array1, *array2;
    NSString*const kServiceName = @"Service";
    NSString*const kServiceName2 = @"Service2";
    double systemVersion = [BNCDevice currentDevice].systemVersion.doubleValue;
    NSString*systemName  = [BNCDevice currentDevice].systemName;

    // Find a signed bundle:

    NSDictionary*dictionary = [BNCApplication entitlementsDictionary];
    NSString*teamID = dictionary[@"com.apple.developer.team-identifier"];
    XCTAssertTrue(teamID.length > 0);
    NSString*bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    XCTAssertTrue(bundleID.length > 0);

    if (teamID.length == 0 || bundleID.length == 0) {
        XCTAssertTrue(bundleID.length > 0 && teamID.length > 0);
        return;
    }
    NSString*securityGroup = [NSString stringWithFormat:@"%@.%@", teamID, bundleID];
    BNCKeyChain*keychain = [[BNCKeyChain alloc] initWithSecurityAccessGroup:securityGroup];

    // Remove and validate gone:

    error = [keychain removeValuesForService:kServiceName key:nil];
    if (![systemName isEqualToString:@"macOS"] && systemVersion >= 10.0 && systemVersion < 11.0)
        { XCTAssertTrue(error == nil || error.code == -34018); }
    else
        { XCTAssertTrue(error == nil); }

    array = [keychain retrieveKeysWithService:kServiceName error:&error];
    XCTAssertTrue(array.count == 0 && error == errSecSuccess);

    // Check some keys:

    value = [keychain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [keychain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    // Test that local storage works:

    error = [keychain storeValue:@"1xyz123" forService:kServiceName key:@"key1"];
    XCTAssertTrue(error == nil);
    value = [keychain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"1xyz123"]);

    error = [keychain storeValue:@"2xyz123" forService:kServiceName key:@"key2"];
    XCTAssertTrue(error == nil);
    value = [keychain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"2xyz123"]);

    error = [keychain storeValue:@"3xyz123" forService:kServiceName2 key:@"key3"];
    XCTAssertTrue(error == nil);
    value = [keychain retrieveValueForService:kServiceName2 key:@"key3" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"3xyz123"]);

    // Remove by service:

    error = [keychain removeValuesForService:kServiceName key:nil];
    value = [keychain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [keychain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [keychain retrieveValueForService:kServiceName2 key:@"key3" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"3xyz123"]);

    // Check service2 values:

    error = [keychain storeValue:@"4xyz123" forService:kServiceName2 key:@"key4"];
    XCTAssertTrue(error == nil);
    array1 = [keychain retrieveKeysWithService:kServiceName2 error:&error];
    array2 = @[ @"key3", @"key4" ];
    XCTAssertTrue([array1 isEqualToArray:array2] && error == errSecSuccess);
}

@end
