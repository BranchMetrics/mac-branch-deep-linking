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
    [branch setUserIdentity:kUserIdentity completion:^ (BranchSession * _Nullable session, NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertEqualObjects(session.userIdentityForDeveloper, kUserIdentity);
            [expectation fulfill];
        }
    ];
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
    XCTAssertTrue(branch.userIdentityIsSet);

    [self resetExpectations];
    expectation = [self expectationWithDescription:@"testLogout"];
    [branch logoutWithCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
    XCTAssertFalse(branch.userIdentityIsSet);
}

- (void)testGetUserIdentityNil {
    Branch *branch = self.branch;
    XCTAssertNil([branch getUserIdentity]);
    XCTAssertFalse(branch.userIdentityIsSet);
}

- (void)testGetUserIdentityEmail {
    NSString *userIdentity = @"sdk@branch.io";
    Branch *branch = self.branch;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSetIdentity"];
    [branch setUserIdentity:userIdentity completion:^ (BranchSession * _Nullable session, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(session.userIdentityForDeveloper, userIdentity);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
    XCTAssertTrue(branch.userIdentityIsSet);
    XCTAssertTrue([userIdentity isEqualToString:[branch getUserIdentity]]);
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
    NSString *alias = [NSString stringWithFormat:@"testAlias_%@", [NSUUID UUID].UUIDString];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinksWithoutBUO"];
    [self.branch branchShortUrlWithParams:( NSDictionary * _Nullable )params andChannel:( NSString * _Nullable )channel andFeature:(NSString * _Nullable)feature andTags:(NSArray * _Nullable)tags andAlias:(NSString * _Nullable)alias andCallback:^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        NSString *expectedURL = [NSString stringWithFormat:@"https://testbed-mac.app.link/%@", alias];
        XCTAssertTrue([shortURL.absoluteString isEqualToString:expectedURL]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testShortLinksWithoutBUO2 {
    
    NSDictionary *params = @{ @"foo-param": @"bar-value" };
    NSString *channel = @"facebook";
    NSString *feature = @"sharing";
    NSArray *tags = @[ @"t1", @"t2" ];
    NSString *alias = [NSString stringWithFormat:@"testAlias_%@", [NSUUID UUID].UUIDString];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testShortLinksWithoutBUO"];
    [self.branch branchShortUrlWithParams:( NSDictionary * _Nullable )params andChannel:( NSString * _Nullable )channel andFeature:(NSString * _Nullable)feature andTags:(NSArray * _Nullable)tags andAlias:(NSString * _Nullable)alias andCallback:^ (NSURL * _Nullable shortURL, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(shortURL);
        NSString *expectedURL = [NSString stringWithFormat:@"https://testbed-mac.app.link/%@", alias];
        XCTAssertTrue([shortURL.absoluteString isEqualToString:expectedURL]);
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

- (void) testSetIdentityAndTrackingDisabled {
    /*
     This test case is for issue -
     https://branch.atlassian.net/browse/CORE-2084
     https://branch.atlassian.net/browse/CORE-2171
     */
    
    // Tracking enabled, Set User Id
    NSString *user1 = @"User1";
    NSString *user2 = @"User2";
    XCTestExpectation *expectUserIdSet = [self expectationWithDescription:@"expectUserIdSet"];
    self.branch.userTrackingDisabled = NO;
    [self.branch setUserIdentity:user1 completion:^(BranchSession * _Nullable session, NSError * _Nullable error) {
        [expectUserIdSet fulfill];
    }];
    [self awaitExpectations];
    // Check if ID is set
    XCTAssertTrue([user1 isEqualToString:[self.branch getUserIdentity]]);
    
    // Disable Tracking and now try to set User Id.
    self.branch.userTrackingDisabled = YES;
    XCTAssertNil([self.branch getUserIdentity]);
    XCTestExpectation *expectUserIdNil = [self expectationWithDescription:@"expectUserIdNil"];
    [self.branch setUserIdentity:user2 completion:^(BranchSession * _Nullable session, NSError * _Nullable error) {
        XCTAssertEqualObjects(error.domain, BNCErrorDomain);
        XCTAssertEqual(error.code, BNCTrackingDisabledError);
        [expectUserIdNil fulfill];
    }];
    [self awaitExpectations];
    // User Id shoudl be nil.
    XCTAssertNil([self.branch getUserIdentity]);
    
    // Enable Tracking and re-open session, then set User Id
    self.branch.userTrackingDisabled = NO;
    self.branch = [[Branch alloc] init];
    [self.branch startWithConfiguration:[[BranchConfiguration alloc] initWithKey:BNCTestBranchKey]];
    BNCSleepForTimeInterval(2.0);
    XCTestExpectation *expectUserIdSetAgain = [self expectationWithDescription:@"expectUserIdSetAgain"];
    [self.branch setUserIdentity:user2 completion:^(BranchSession * _Nullable session, NSError * _Nullable error) {
        [expectUserIdSetAgain fulfill];
    }];
    [self awaitExpectations];
    // Assert if User Id is set?
    XCTAssertTrue([user2 isEqualToString:[self.branch getUserIdentity]]);
}

@end
