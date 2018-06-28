//
//  BranchDelegateTest.m
//  Branch-SDK-Tests
//
//  Created by Edward Smith on 11/3/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchMainClass.h"
#import "BranchDelegate.h"
#import "BranchError.h"

@interface BranchDelegateTest : BNCTestCase <BranchDelegate>
@property (assign, nonatomic) NSInteger notificationOrder;
@property (strong, nonatomic) XCTestExpectation *branchWillStartSessionExpectation;
@property (strong, nonatomic) XCTestExpectation *branchWillStartSessionNotificationExpectation;

@property (strong, nonatomic) XCTestExpectation *branchCallbackExpectation;

@property (strong, nonatomic) XCTestExpectation *branchDidStartSessionExpectation;
@property (strong, nonatomic) XCTestExpectation *branchDidStartSessionNotificationExpectation;

@property (strong, nonatomic) XCTestExpectation *branchDidOpenURLExpectation;
@property (strong, nonatomic) XCTestExpectation *branchDidOpenURLNotificationExpectation;

//@property (strong, nonatomic) NSDictionary *deepLinkParams;
@property (assign, nonatomic) BOOL expectFailure;
@end

#pragma mark - BranchDelegateTest

@implementation BranchDelegateTest

// Test that Branch notifications work.
// Test that they 1) work and 2) are sent in the right order.
- (void) testNotificationsSuccess {

    self.expectFailure = NO;
    self.notificationOrder = 0;

    self.branchWillStartSessionExpectation = [self expectationWithDescription:@"branchWillStartSessionExpectation"];
    self.branchWillStartSessionNotificationExpectation = [self expectationWithDescription:@"branchWillStartSessionNotificationExpectation"];

    self.branchCallbackExpectation = [self expectationWithDescription:@"branchCallbackExpectation"];

    self.branchDidStartSessionExpectation = [self expectationWithDescription:@"branchDidStartSessionExpectation"];
    self.branchDidStartSessionNotificationExpectation = [self expectationWithDescription:@"branchDidStartSessionNotificationExpectation"];

    self.branchDidOpenURLExpectation = [self expectationWithDescription:@"branchDidOpenURLExpectation"];
    self.branchDidOpenURLNotificationExpectation = [self expectationWithDescription:@"branchDidOpenURLNotificationExpectation"];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchWillStartSessionNotification:)
        name:BranchWillStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidOpenURLWithSessionNotification:)
        name:BranchDidOpenURLWithSessionNotification
        object:nil];

    // Set up the network mock:
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        if ([request.HTTPMethod isEqualToString:@"POST"] &&
            ([request.URL.path hasSuffix:@"/v1/open"] ||
             [request.URL.path hasSuffix:@"/v1/install"])) {
            NSString*response = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
            XCTAssertNotNil(response);
            return [BNCTestNetworkService operationWithRequest:request response:response];
        }
        return [BNCTestNetworkService operationWithRequest:request response:@""];
    };

    // Start Branch:
    BranchConfiguration*configuration =
        [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    branch.delegate = self;
    branch.startSessionBlock = ^(BranchSession * _Nullable session, NSError * _Nullable error) {
        // Callback block. Order: 2.
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertNotNil(session);
        XCTAssertNil(error);
        XCTAssertEqualObjects(session.sessionID, @"534369161321890489");
        XCTAssertEqual(self.notificationOrder, 2);
        self.notificationOrder++;
        [self.branchCallbackExpectation fulfill];
    };
    [branch startWithConfiguration:configuration];

    [self waitForExpectationsWithTimeout:5.0 handler:NULL];
    XCTAssertEqual(self.notificationOrder, 7);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    branch.delegate = nil;
}

// Test that Branch notifications work with a failure.
// Test that they 1) work and 2) are sent in the right order.
- (void) testNotificationsFailure {
    self.expectFailure = YES;
    self.notificationOrder = 0;

    self.branchWillStartSessionExpectation = [self expectationWithDescription:@"branchWillStartSessionExpectation"];
    self.branchWillStartSessionNotificationExpectation = [self expectationWithDescription:@"branchWillStartSessionNotificationExpectation"];

    self.branchCallbackExpectation = [self expectationWithDescription:@"branchCallbackExpectation"];

    self.branchDidStartSessionExpectation = [self expectationWithDescription:@"branchDidStartSessionExpectation"];
    self.branchDidStartSessionNotificationExpectation = [self expectationWithDescription:@"branchDidStartSessionNotificationExpectation"];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchWillStartSessionNotification:)
        name:BranchWillStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidOpenURLWithSessionNotification:)
        name:BranchDidOpenURLWithSessionNotification
        object:nil];

    // Set up the network mock:
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        if ([request.HTTPMethod isEqualToString:@"POST"] &&
            ([request.URL.path hasSuffix:@"/v1/open"] ||
             [request.URL.path hasSuffix:@"/v1/install"])) {
            NSString*response = [self stringFromBundleJSONWithKey:@"BranchOpenResponseMac"];
            XCTAssertNotNil(response);
            BNCTestNetworkOperation*operation = [BNCTestNetworkService operationWithRequest:request response:response];
            operation.error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError];
            return operation;
        }
        return [BNCTestNetworkService operationWithRequest:request response:@""];
    };

    // Start Branch:
    BranchConfiguration*configuration =
        [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    branch.delegate = self;
    branch.startSessionBlock = ^(BranchSession * _Nullable session, NSError * _Nullable error) {
        // Callback block. Order: 2.
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertNil(session);
        XCTAssertNotNil(error);
        XCTAssertEqual(self.notificationOrder, 2);
        self.notificationOrder++;
        [self.branchCallbackExpectation fulfill];
    };
    [branch startWithConfiguration:configuration];

    [self waitForExpectationsWithTimeout:5.0 handler:NULL];
    BNCSleepForTimeInterval(0.200); // Wait to drain any outstanding double fulfillments.
    XCTAssertEqual(self.notificationOrder, 5);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    branch.delegate = nil;
}

#pragma mark - Delegate & Notification Methods

// Delegate method. Order: 0.
- (void) branch:(Branch*)branch willStartSessionWithURL:(NSURL*)url {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNotNil(branch);
    XCTAssertNil(url);
    XCTAssertEqual(self.notificationOrder, 0);
    self.notificationOrder++;
    [self.branchWillStartSessionExpectation fulfill];
}

// Notification method. Order: 1.
- (void) branchWillStartSessionNotification:(NSNotification*)notification {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertEqual(self.notificationOrder, 1);
    self.notificationOrder++;

    XCTAssertTrue([notification.object isKindOfClass:[Branch class]]);

    BranchSession*session = notification.userInfo[BranchSessionKey];
    XCTAssertNil(session);

    NSURL*URL = notification.userInfo[BranchURLKey];
    XCTAssertNil(URL);

    NSError *error = notification.userInfo[BranchErrorKey];
    XCTAssertNil(error);

    [self.branchWillStartSessionNotificationExpectation fulfill];
}

// Delegate method. Order: 3.
- (void) branch:(Branch*)branch didStartSession:(BranchSession*)session {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNotNil(branch);
    XCTAssertNotNil(session);
    XCTAssertEqual(self.notificationOrder, 3);
    self.notificationOrder++;
    if (self.expectFailure)
        [NSException raise:NSInternalInconsistencyException format:@"Should return an error here."];
    [self.branchDidStartSessionExpectation fulfill];
}

// Delegate method: failure. Order: 3
- (void) branch:(Branch*)branch
failedToStartSessionWithURL:(NSURL*)url
                      error:(NSError*)error {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNil(url);
    XCTAssertNotNil(error);
    XCTAssertEqual(self.notificationOrder, 3);
    self.notificationOrder++;
    if (!self.expectFailure)
        [NSException raise:NSInternalInconsistencyException format:@"Shouldn't return an error here."];
    [self.branchDidStartSessionExpectation fulfill];
}

// Notification method. Order: 4
- (void) branchDidStartSessionNotification:(NSNotification*)notification {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertEqual(self.notificationOrder, 4);
    self.notificationOrder++;

    XCTAssertTrue([notification.object isKindOfClass:[Branch class]]);

    if (self.expectFailure) {
        BranchSession*session = notification.userInfo[BranchSessionKey];
        XCTAssertNil(session);

        NSURL*URL = notification.userInfo[BranchURLKey];
        XCTAssertNil(URL);

        NSError *error = notification.userInfo[BranchErrorKey];
        XCTAssertNotNil(error);
    } else {
        BranchSession*session = notification.userInfo[BranchSessionKey];
        XCTAssertNotNil(session);

        NSURL*URL = notification.userInfo[BranchURLKey];
        XCTAssertNil(URL);

        NSError *error = notification.userInfo[BranchErrorKey];
        XCTAssertNil(error);
    }
    [self.branchDidStartSessionNotificationExpectation fulfill];
}

// Delegate method. Order: 5
- (void) branch:(Branch *)branch didOpenURLWithSession:(BranchSession *)session {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNotNil(branch);
    XCTAssertNotNil(session);
    XCTAssertEqual(self.notificationOrder, 5);
    self.notificationOrder++;
    [self.branchDidOpenURLExpectation fulfill];
}

// Notification method. Order: 6
- (void) branchDidOpenURLWithSessionNotification:(NSNotification*)notification {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertEqual(self.notificationOrder, 6);
    self.notificationOrder++;

    XCTAssertTrue([notification.object isKindOfClass:[Branch class]]);

    BranchSession*session = notification.userInfo[BranchSessionKey];
    XCTAssertNotNil(session);

    NSURL*URL = notification.userInfo[BranchURLKey];
    XCTAssertNil(URL);

    NSError*error = notification.userInfo[BranchErrorKey];
    XCTAssertNil(error);

    [self.branchDidOpenURLNotificationExpectation fulfill];
}

@end
