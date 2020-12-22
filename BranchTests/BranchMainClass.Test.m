/**
 @file          BranchMainClass.Test.m
 @package       BranchTests
 @brief         Tests the top level entry points of the Branch class.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BranchError.h"
#import "BNCLog.h"

@interface BranchMainTest : BNCTestCase
@property (strong) Branch*branch;
@end

@implementation BranchMainTest

- (void) setUp {
    if (!self.branch) {
        self.branch = [[Branch alloc] init];
        [self.branch startWithConfiguration:[[BranchConfiguration alloc] initWithKey:BNCTestBranchKey]];
        BNCSleepForTimeInterval(2.0);   // TODO: remove Wait for open to happen.
    }
}

- (void)testSingleton {
    Branch*b1 = Branch.sharedInstance;
    Branch*b2 = Branch.sharedInstance;
    XCTAssertNotNil(b1);
    XCTAssertEqual(b1, b2);
}

- (void) testKitDetails {
    // TODO: Change sdk bundle ID for tvos?
    XCTAssertEqualObjects(Branch.bundleIdentifier, @"io.branch.sdk.mac");
    XCTAssertTrue(Branch.kitDisplayVersion.length >= 5);
    XCTAssertEqualObjects(Branch.kitDisplayVersion,
        [NSBundle bundleForClass:Branch.class].infoDictionary[@"CFBundleShortVersionString"]);
}

- (void) testBadConfiguration {
    BranchConfiguration*config = [[BranchConfiguration alloc] initWithKey:@""];
    Branch*badBranch = [[Branch alloc] init];
    XCTAssertThrows([badBranch startWithConfiguration:config], @"Expected bad configuration.");
    XCTAssertTrue([config.description hasPrefix:@"<BranchConfiguration 0x"]);
}

- (void) testLogging {
    Branch.loggingEnabled = YES;
    XCTAssertTrue(Branch.loggingIsEnabled);
    BNCLogDebug(@"Debug!");
    BNCLogFlushMessages();
    NSLog(@"Flushed 1.");

    Branch.loggingEnabled = NO;
    XCTAssertFalse(Branch.loggingIsEnabled);
    BNCLogDebug(@"Debug!");
    BNCLogFlushMessages();
    NSLog(@"Flushed 2.");
}

- (void) testSetIdentity {
    NSString*const kUserIdentity = @"Nada";
    Branch*branch = self.branch;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSetIdentity"];
    [branch setUserIdentity:kUserIdentity
        completion:^ (BranchSession * _Nullable session, NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertEqualObjects(session.userIdentityForDeveloper, kUserIdentity);
            [expectation fulfill];
        }
    ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(branch.userIdentityIsSet);

    [self resetExpectations];
    expectation = [self expectationWithDescription:@"testLogout"];
    [branch logoutWithCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertFalse(branch.userIdentityIsSet);
}

- (void) testShortLinks {
    BranchUniversalObject*buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"id-123"];
    buo.title = @"Test link";
    buo.canonicalUrl = @"https://branch.io/docs/unit-tests";
    BranchLinkProperties*lp = [[BranchLinkProperties alloc] init];
    lp.channel = @"UnitTests";
    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinks"];
    [self.branch branchShortLinkWithContent:buo linkProperties:lp completion:
    ^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        XCTAssertTrue([shortURL.absoluteString hasPrefix:@"https://testbed-mac.app.link/"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


- (void) testShortLinksWithoutBUONillParams {
    
    NSDictionary *params = nil;
    NSString *channel = nil;
    NSString *feature = nil;
    NSArray *tags = nil;
    NSString *alias =  nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinksWithoutBUO"];
    [self.branch branchShortUrlWithParams:( NSDictionary * _Nullable )params andChannel:( NSString * _Nullable )channel andFeature:(NSString * _Nullable)feature andTags:(NSArray * _Nullable)tags andAlias:(NSString * _Nullable)alias andCallback:^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        XCTAssertTrue([shortURL.absoluteString hasPrefix:@"https://testbed-mac.app.link/"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testShortLinksWithoutBUO1 {
    
    NSDictionary *params = nil;
    NSString *channel = @"facebook";
    NSString *feature = @"sharing";
    NSArray *tags = @[ @"t1", @"t2" ];
    NSString *alias =  @"testAlias";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinksWithoutBUO"];
    [self.branch branchShortUrlWithParams:( NSDictionary * _Nullable )params andChannel:( NSString * _Nullable )channel andFeature:(NSString * _Nullable)feature andTags:(NSArray * _Nullable)tags andAlias:(NSString * _Nullable)alias andCallback:^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        XCTAssertTrue([shortURL.absoluteString isEqualToString:@"https://testbed-mac.app.link/testAlias"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testShortLinksWithoutBUO2 {
    
    NSDictionary *params = @{ @"foo-param": @"bar-value" };
    NSString *channel = @"facebook";
    NSString *feature = @"sharing";
    NSArray *tags = @[ @"t1", @"t2" ];
    NSString *alias =  @"testAlias";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinksWithoutBUO"];
    [self.branch branchShortUrlWithParams:( NSDictionary * _Nullable )params andChannel:( NSString * _Nullable )channel andFeature:(NSString * _Nullable)feature andTags:(NSArray * _Nullable)tags andAlias:(NSString * _Nullable)alias andCallback:^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        XCTAssertTrue([shortURL.absoluteString isEqualToString:@"https://testbed-mac.app.link/testAlias"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testLongLinks {
    BranchLinkProperties*lp = [BranchLinkProperties new];
    lp.tags = @[ @"t1", @"t2" ];
    lp.feature = @"feature";
    lp.alias = @"alias";
    lp.channel = @"channel";
    lp.stage = @"stage";
    lp.campaign = @"campaign";
    lp.matchDuration = 600;
    lp.linkType = BranchLinkTypeOneTimeUse;
    lp.controlParams = (id) @{ @"cp1": @"cp1v" };

    NSDictionary *dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    XCTAssert(dictionary);
    BranchUniversalObject *buo = [BranchUniversalObject objectWithDictionary:dictionary];
    XCTAssert(buo);

    NSURL*longURL = [self.branch branchLongLinkWithContent:buo linkProperties:lp];
    NSString*test = longURL.absoluteString;
    NSString*truth = [self stringFromBundleWithKey:@"LongLinkURL"];
    XCTAssertEqualObjects(test, truth);
}

- (void) testSetTrackingDisabled {
    self.branch.userTrackingDisabled = YES;
    Branch*branch = self.branch;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinks"];
    [branch setUserIdentity:@"Bob" completion:^(BranchSession * _Nullable session, NSError * _Nullable error) {
        XCTAssertEqualObjects(error.domain, BNCErrorDomain);
        XCTAssertEqual(error.code, BNCTrackingDisabledError);
        [expectation fulfill];
    }];
    [self awaitExpectations];
    self.branch.userTrackingDisabled = NO;
}

- (void) testSendClose {
    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;

    XCTestExpectation *expectation = [self expectationWithDescription:@"testSendClose"];
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            if ([request.URL.path isEqualToString:@"/v1/close"]) {
                NSDictionary*test = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                XCTAssertGreaterThan(test.count, 1);
                [expectation fulfill];
            }
            BNCTestNetworkOperation*operation = [BNCTestNetworkService operationWithRequest:request response:@"{}"];
            return operation;
        };

    [branch startWithConfiguration:configuration];
    BNCSleepForTimeInterval(1.0); // TODO: Fix Sleep: open should happen without sleep.
    [branch endSession];
    [self awaitExpectations];
}

@end
