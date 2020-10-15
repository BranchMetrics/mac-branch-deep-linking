//
/**
 @file          BranchV2Event.m
 @package       BranchTests
 @brief         Unit Tests for V2 Events

 @author        Nidhi
 @date          2020
 @copyright     Copyright © 2020 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "BNCTestCase.h"
#import "BranchEvent.h"
#import "BNCDevice.h"
#import "BranchMainClass.h"
#import "BNCNetworkAPIService.h"

@interface BranchV2EventTest : XCTestCase{
    BranchUniversalObject *buo;
    NSMutableArray<BranchUniversalObject *> *contentItems;
    Branch *branch;
}
@end

@implementation BranchV2EventTest

- (void)setUp {
    
    buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    
    BranchConfiguration *configuration = [[BranchConfiguration alloc] initWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    
    branch = [[Branch alloc] init];
    [branch startWithConfiguration:configuration];
    [branch.networkAPIService clearNetworkQueue];
}

- (void)tearDown {
    
}

- (void)testStandardInviteEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventInvite];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardInviteEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}
- (void)testCustomInviteEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"INVITE"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomInviteEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
}

- (void)testStandardLoginEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventLogin];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardLoginEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
}

- (void)testCustomLoginEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"LOGIN"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomLoginEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testStandardReserveEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventReserve];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardReserveEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testCustomReserveEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"RESERVE"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomReserveEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testStandardSubscribeEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventSubscribe];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardSubscribeEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testCustomSubscribeEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"SUBSCRIBE"];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomSubscribeEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testStandardStartTrialEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventStartTrial];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardStartTrialEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testCustomStartTrialEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"START_TRIAL"];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomStartTrialEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testStandardClickAdEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventClickAd];
    event.adType = BranchEventAdTypeBanner;
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardClickAdEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testCustomClickAdEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"CLICK_AD"];
    event.adType = BranchEventAdTypeBanner;
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomClickAdEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testStandardViewAdEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    event.adType = BranchEventAdTypeBanner;
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testStandardViewAdEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testCustomViewAdEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"VIEW_AD"];
    event.adType = BranchEventAdTypeBanner;
    event.contentItems = contentItems;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCustomViewAdEvent"];
       [branch logEvent:event completion:
           ^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [expectation fulfill];
           }
       ];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

@end
