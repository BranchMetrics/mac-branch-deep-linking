//
//  BNCUserAgentCollectorTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "BNCUserAgentCollector.h"

// expose private methods for unit testing
@interface BNCUserAgentCollector()

+ (NSString *)userAgentKey;
+ (NSString *)systemBuildVersionKey;

- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion;
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion;

- (void)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion withCompletion:(void (^)(NSString *userAgent))completion;

- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion;

@end

@interface BNCUserAgentCollectorTests : XCTestCase

@end

@implementation BNCUserAgentCollectorTests

+ (void)setUp {
    [BNCUserAgentCollectorTests resetPersistentData];
}

- (void)setUp {

}

- (void)tearDown {
    [BNCUserAgentCollectorTests resetPersistentData];
}

+ (void)resetPersistentData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:[BNCUserAgentCollector userAgentKey]];
    [defaults setObject:nil forKey:[BNCUserAgentCollector systemBuildVersionKey]];
}

- (void)testResetPersistentData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedUserAgent = (NSString *)[defaults valueForKey:[BNCUserAgentCollector userAgentKey]];
    NSString *savedSystemBuildVersion = (NSString *)[defaults valueForKey:[BNCUserAgentCollector systemBuildVersionKey]];
    
    XCTAssertNil(savedUserAgent);
    XCTAssertNil(savedSystemBuildVersion);
}

- (void)testSaveAndLoadUserAgent {
    NSString *systemBuildVersion = @"test";
    NSString *userAgent = @"UserAgent";

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
    NSString *expected = [collector loadUserAgentForSystemBuildVersion:systemBuildVersion];
    XCTAssertTrue([userAgent isEqualToString:expected]);
}

- (void)testCollectUserAgent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_EmptyDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    NSString *systemBuildVersion = @"test";

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector loadUserAgentForSystemBuildVersion:systemBuildVersion withCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_FilledDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    NSString *systemBuildVersion = @"test";
    NSString *savedUserAgent = @"UserAgent";
    
    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector saveUserAgent:savedUserAgent forSystemBuildVersion:systemBuildVersion];
    [collector loadUserAgentForSystemBuildVersion:systemBuildVersion withCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent isEqualToString:savedUserAgent]);
        XCTAssertFalse([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

@end
