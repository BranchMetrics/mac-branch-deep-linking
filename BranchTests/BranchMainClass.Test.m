/**
 @file          BranchMainClass.Test.m
 @package       BranchTests
 @brief         Tests the top level entry points of the Branch class.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCLog.h"

@interface BranchMainTest : BNCTestCase
@property (strong) Branch*branch;
@end

@implementation BranchMainTest

- (void) setUp {
    if (!self.branch) {
        self.branch = [[Branch alloc] init];
        [self.branch startWithConfiguration:[[BranchConfiguration alloc] initWithKey:BNCTestBranchKey]];
        BNCSleepForTimeInterval(2.0);   // TODO: remove
    }
}

- (void) testKitDetails {
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
    self.branch.loggingEnabled = YES;
    XCTAssertTrue(self.branch.loggingIsEnabled);
    BNCLogDebug(@"Debug!");
    BNCLogFlushMessages();
    NSLog(@"Flushed 1.");

    self.branch.loggingEnabled = NO;
    XCTAssertFalse(self.branch.loggingIsEnabled);
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

- (void) testShortLinkBadNetwork {
    // TODO: Finish this.
    // XCTAssert(NO, @"Write this test.");
}

//### Functional Tests
//* [ ] Make long link.
//* [ ] Tracking disabled: Test setting persistence, open link work, long links work, else fail.

@end
