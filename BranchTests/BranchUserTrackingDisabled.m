//
/**
 @file          BranchUserTrackingDisabled.m
 @package       BranchTests
 @brief         Tests creation of short link when tracking is disabled.

 @author        Nidhi Dixit
 @date          2020
 @copyright     Copyright © 2020 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "BNCTestCase.h"
#import "BranchError.h"
#import "BNCLog.h"

@interface BranchUserTrackingDisabled : XCTestCase
@property (strong) Branch   *branch;
@end

@implementation BranchUserTrackingDisabled

- (void)setUp {
    if (!self.branch) {
        self.branch = [[Branch alloc] init];
        [self.branch startWithConfiguration:[[BranchConfiguration alloc] initWithKey:BNCTestBranchKey]];
        self.branch.userTrackingDisabled = YES;
    }
}

- (void)tearDown {
    if (self.branch)
        self.branch.userTrackingDisabled = NO;
}

- (void)testShortLink {
    
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"id-123"];
    buo.title = @"Test link";
    buo.canonicalUrl = @"https://branch.io/docs/unit-tests";
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
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


@end
