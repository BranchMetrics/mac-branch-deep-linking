/**
 @file          BNCURLBlackList.Test.m
 @package       Branch-SDK-Tests
 @brief         BNCURLBlackList tests.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCURLBlackList.h"
#import "BranchMainClass.h"

@interface BNCURLBlackList ()
@property (readwrite) NSURL *blackListJSONURL;
@end

@interface BNCURLBlackListTest : BNCTestCase
@end

@implementation BNCURLBlackListTest

- (void) setUp {
}

- (void) tearDown {
}

- (void)testListDownLoad {
    XCTestExpectation *expectation = [self expectationWithDescription:@"BlackList Download"];
    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    [branch startWithConfiguration:configuration];
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    [blackList refreshBlackListFromServerWithBranch:branch completion:
        ^(BNCURLBlackList * _Nonnull blackList, NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertTrue(blackList.blackList.count == 6);
            [expectation fulfill];
        }
    ];
    [self awaitExpectations];
}

- (NSArray*) badURLs {
    NSArray *kBadURLs = @[
        @"fb123456:login/464646",
        @"twitterkit-.4545:",
        @"shsh:oauth/login",
        @"https://myapp.app.link/oauth_token=fred",
        @"https://myapp.app.link/auth_token=fred",
        @"https://myapp.app.link/authtoken=fred",
        @"https://myapp.app.link/auth=fred",
        @"fb1234:",
        @"fb1234:/",
        @"fb1234:/this-is-some-extra-info/?whatever",
        @"fb1234:/this-is-some-extra-info/?whatever:andstuff",
        @"myscheme:path/to/resource?oauth=747474",
        @"myscheme:oauth=747474",
        @"myscheme:/oauth=747474",
        @"myscheme://oauth=747474",
        @"myscheme://path/oauth=747474",
        @"myscheme://path/:oauth=747474",
        @"https://google.com/userprofile/devonbanks=oauth?",
    ];
    return kBadURLs;
}

- (NSArray*) goodURLs {
    NSArray *kGoodURLs = @[
        @"shshs:/content/path",
        @"shshs:content/path",
        @"https://myapp.app.link/12345/link",
        @"fb123x:/",
        @"https://myapp.app.link?authentic=true&tokemonsta=false",
        @"myscheme://path/brauth=747474",
    ];
    return kGoodURLs;
}

- (void)testBadURLs {
    // Test default list.
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    for (NSString *string in self.badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([blackList isBlackListedURL:URL], @"Checking '%@'.", URL);
    }
}

- (void) testDownloadBadURLs {
    // Test download list.
    XCTestExpectation *expectation = [self expectationWithDescription:@"testDownloadBadURLs"];

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    [branch startWithConfiguration:configuration];

    BNCURLBlackList *blackList = [BNCURLBlackList new];
    blackList.blackListJSONURL = [NSURL URLWithString:@"https://cdn.branch.io/sdk/uriskiplist_tv1.json"];
    [blackList refreshBlackListFromServerWithBranch:branch completion:
        ^(BNCURLBlackList * _Nonnull blackList, NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertTrue(blackList.blackList.count == 7);
            [expectation fulfill];
        }
    ];
    [self awaitExpectations];
    for (NSString *string in self.badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([blackList isBlackListedURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testGoodURLs {
    // Test default list.
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    for (NSString *string in self.goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([blackList isBlackListedURL:URL], @"Checking '%@'", URL);
    }
}

- (void) testDownloadGoodURLs {
    // Test download list.

    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    [branch startWithConfiguration:configuration];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testDownloadGoodURLs"];
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    blackList.blackListJSONURL = [NSURL URLWithString:@"https://cdn.branch.io/sdk/uriskiplist_tv1.json"];
    [blackList refreshBlackListFromServerWithBranch:branch completion:
        ^(BNCURLBlackList * _Nonnull blackList, NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertEqual(blackList.blackList.count, 7);
            [expectation fulfill];
        }
    ];
    [self awaitExpectations];
    for (NSString *string in self.goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([blackList isBlackListedURL:URL], @"Checking '%@'.", URL);
    }
}

- (void) testStandardBlackList {
    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block NSInteger callCount = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardBlackList"];
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            ++callCount;
            if (callCount == 1) {
                NSDictionary*dictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                NSLog(@"URL: %@", request.URL);
                NSLog(@"d: %@", dictionary);
                NSString* link = dictionary[@"external_intent_uri"];
                NSString *pattern =
                    @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b";
                    // @"^(?i).+:.*[?].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b";
                NSLog(@"\n   Link: '%@'\nPattern: '%@'\n.", link, pattern);
                XCTAssertEqualObjects(link, pattern);
                BNCAfterSecondsPerformBlockOnMainThread(0.2, ^{ [expectation fulfill]; });
            }
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        };

    NSString *url = @"https://myapp.app.link/bob/link?oauth=true";
    #if TARGET_OS_OSX
    url = @"testbed-mac://open?link_click_id=348527481794276288&oauth=true";
    #endif

    [branch openURL:[NSURL URLWithString:url]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testUserBlackList {
    Branch*branch = [Branch new];
    BranchConfiguration*configuration = [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    configuration.blackListURLRegex = @[
        @"\\/bob\\/"
    ];
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];

    __block NSInteger callCount = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testUserBlackList"];
    BNCTestNetworkService.requestHandler =
        ^ id<BNCNetworkOperationProtocol> _Nonnull(NSMutableURLRequest * _Nonnull request) {
            // Called twice: once for open and once to get list
            ++callCount;
            if (callCount == 1) {
                XCTAssertEqualObjects(request.HTTPMethod, @"POST");
                XCTAssertEqualObjects(request.URL.path, @"/v1/install");
                NSDictionary*dictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
                NSLog(@"d: %@", dictionary);
                NSString* link = dictionary[@"external_intent_uri"];
                NSString *pattern =  @"\\/bob\\/";
                NSLog(@"\n   Link: '%@'\nPattern: '%@'\n.", link, pattern);
                XCTAssertEqualObjects(link, pattern);
                BNCAfterSecondsPerformBlockOnMainThread(0.2, ^{ [expectation fulfill]; });
            }
            return [BNCTestNetworkService operationWithRequest:request response:@"{}"];
        };

    NSString *url = @"https://myapp.app.link/bob/link";
    #if TARGET_OS_OSX
    url = @"testbed-mac://bob/open?link_click_id=348527481794276288&oauth=true";
    #endif

    [branch openURL:[NSURL URLWithString:url]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
