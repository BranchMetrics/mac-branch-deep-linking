//
//  BranchEvent.Test.m
//  Branch-SDK-Tests
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchEvent.h"
#import "BNCDevice.h"
#import "BranchMainClass.h"
#import "BNCNetworkAPIService.h"

@interface BranchEventTest : BNCTestCase
@end

@implementation BranchEventTest

- (void) testDescription {
    BranchEvent *event    = [BranchEvent standardEvent:BranchStandardEventPurchase];
    event.transactionID   = @"1234";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"10.50"];
    event.eventDescription= @"Event description.";
    event.customData      = (NSMutableDictionary*) @{
        @"Key1": @"Value1"
    };

    NSString *d = event.description;
    BNCTAssertEqualMaskedString(d,
        @"<BranchEvent 0x**************** PURCHASE txID: 1234 Amt: USD 10.5 desc: Event description. "
         "items: 0 customData: {\n    Key1 = Value1;\n}>");
}

- (void) testEvent {

    // Set up the Branch Universal Object --

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    buo.imageUrl            = @"https://test_img_url";
    buo.keywords            = @[ @"My_Keyword1", @"My_Keyword2"];
    buo.creationDate        = [NSDate dateWithTimeIntervalSince1970:1501869445321.0/1000.0];
    buo.expirationDate      = [NSDate dateWithTimeIntervalSince1970:212123232544.0/1000.0];
    buo.locallyIndex        = YES;
    buo.publiclyIndex       = NO;

    buo.contentMetadata.contentSchema    = BranchContentSchemaCommerceProduct;
    buo.contentMetadata.quantity         = 2;
    buo.contentMetadata.price            = [NSDecimalNumber decimalNumberWithString:@"23.2"];
    buo.contentMetadata.currency         = BNCCurrencyUSD;
    buo.contentMetadata.sku              = @"1994320302";
    buo.contentMetadata.productName      = @"my_product_name1";
    buo.contentMetadata.productBrand     = @"my_prod_Brand1";
    buo.contentMetadata.productCategory  = BNCProductCategoryBabyToddler;
    buo.contentMetadata.productVariant   = @"3T";
    buo.contentMetadata.condition        = BranchConditionFair;

    buo.contentMetadata.ratingAverage    = 5;
    buo.contentMetadata.ratingCount      = 5;
    buo.contentMetadata.ratingMax        = 7;
    buo.contentMetadata.rating           = 6;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (NSMutableDictionary*) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1",
        @"Custom_Content_metadata_key2": @"Custom_Content_metadata_val2"
    };

    // Set up the event properties --

    BranchEvent *event    = [BranchEvent standardEvent:BranchStandardEventPurchase];
    event.transactionID   = @"12344555";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    event.shipping        = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    event.tax             = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    event.coupon          = @"test_coupon";
    event.affiliation     = @"test_affiliation";
    event.eventDescription= @"Event _description";
    event.searchQuery     = @"Query";
    event.customData      = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };

    // Check the BUO:

    NSDictionary *testDictionary = [event dictionary];
    NSMutableDictionary *dictionary =
        [self mutableDictionaryFromBundleJSONWithKey:@"V2EventProperties"];
    XCTAssertEqualObjects(testDictionary, dictionary);

    testDictionary = [buo dictionary];
    dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    XCTAssertEqualObjects(testDictionary, dictionary);

    BranchConfiguration*configuration =
        [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:configuration];

    event.contentItems = (NSMutableArray*) @[ buo ];

    // Mock the result. Fix up the expectedParameters for simulator hardware --

    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        XCTAssertEqualObjects(request.HTTPMethod, @"POST");
        XCTAssertEqualObjects(request.URL.path, @"/v2/event/standard");

        NSMutableDictionary *expectedRequest =
            [self mutableDictionaryFromBundleJSONWithKey:@"V2EventJSON"];
        XCTAssertNotNil(expectedRequest);
        [branch.networkAPIService appendV2APIParametersWithDictionary:expectedRequest];
        expectedRequest[@"retry_number"] = nil;
        
        NSMutableDictionary*requestDictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
        XCTAssertNotNil(requestDictionary);

        XCTAssertEqualObjects(expectedRequest, requestDictionary);

        NSString*responseString = [self stringFromBundleJSONWithKey:@"V2EventJSONResponse"];
        return [BNCTestNetworkService operationWithRequest:request response:responseString];
    };

    [branch.networkAPIService clearNetworkQueue];
    XCTestExpectation *expectation = [self expectationWithDescription:@"v2-event"];
    [branch logEvent:event completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testUserCompletedAction {
    // Mock the result. Fix up the expectedParameters for simulator hardware --

    XCTestExpectation *expectation = [self expectationWithDescription:@"v2-event-user-action"];
    BNCTestNetworkService.requestHandler = ^ id<BNCNetworkOperationProtocol> (NSMutableURLRequest*request) {
        XCTAssertEqualObjects(request.HTTPMethod, @"POST");
        XCTAssertEqualObjects(request.URL.path, @"/v2/event/standard");

        NSMutableDictionary*requestDictionary = [BNCTestNetworkService mutableDictionaryFromRequest:request];
        NSMutableDictionary*expectedRequest = [self mutableDictionaryFromBundleJSONWithKey:@"V2EventJSON"];
        expectedRequest[@"custom_data"] = nil;
        expectedRequest[@"event_data"] = nil;

        XCTAssertEqualObjects(expectedRequest, requestDictionary);

        NSString*responseString = [self stringFromBundleJSONWithKey:@"V2EventJSONResponse"];
        BNCAfterSecondsPerformBlock(0.01, ^{ [expectation fulfill]; });
        return [BNCTestNetworkService operationWithRequest:request response:responseString];
    };

    BranchConfiguration*configuration =
        [BranchConfiguration configurationWithKey:@"key_live_foo"];
    configuration.networkServiceClass = BNCTestNetworkService.class;
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:configuration];

    // Set up the Branch Univseral Object --

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    buo.imageUrl            = @"https://test_img_url";
    buo.keywords            = @[ @"My_Keyword1", @"My_Keyword2"];
    buo.creationDate        = [NSDate dateWithTimeIntervalSince1970:1501869445321.0/1000.0];
    buo.expirationDate      = [NSDate dateWithTimeIntervalSince1970:212123232544.0/1000.0];
    buo.locallyIndex        = YES;
    buo.publiclyIndex       = NO;

    buo.contentMetadata.contentSchema    = BranchContentSchemaCommerceProduct;
    buo.contentMetadata.quantity         = 2;
    buo.contentMetadata.price            = [NSDecimalNumber decimalNumberWithString:@"23.2"];
    buo.contentMetadata.currency         = BNCCurrencyUSD;
    buo.contentMetadata.sku              = @"1994320302";
    buo.contentMetadata.productName      = @"my_product_name1";
    buo.contentMetadata.productBrand     = @"my_prod_Brand1";
    buo.contentMetadata.productCategory  = BNCProductCategoryBabyToddler;
    buo.contentMetadata.productVariant   = @"3T";
    buo.contentMetadata.condition        = @"FAIR";
    buo.contentMetadata.ratingAverage    = 5;
    buo.contentMetadata.ratingCount      = 5;
    buo.contentMetadata.ratingMax        = 7;
    buo.contentMetadata.rating           = 6;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (NSMutableDictionary*) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1",
        @"Custom_Content_metadata_key2": @"Custom_Content_metadata_val2"
    };

    // Set up and invoke --
    [branch logEvent:[BranchEvent standardEvent:BranchStandardEventPurchase contentItem:buo] completion:nil];
    //[buo userCompletedAction:BranchStandardEventPurchase];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testExampleSyntax {
    BranchUniversalObject *contentItem = [BranchUniversalObject new];
    contentItem.canonicalIdentifier = @"item/123";
    contentItem.canonicalUrl = @"https://branch.io/item/123";
    contentItem.contentMetadata.ratingAverage = 5.0;

    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventCompleteRegistration];
    event.eventDescription = @"Product Search";
    event.searchQuery = @"product name";
    event.customData[@"rating"] = @"5";

    BranchConfiguration*configuration =
        [BranchConfiguration configurationWithKey:@"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N"];
    Branch*branch = [[Branch alloc] init];
    [branch startWithConfiguration:configuration];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testExampleSyntax"];
    [branch logEvent:event completion:^ (NSError*error) {
        XCTAssert(error == nil);
        [expectation fulfill];
    }];
    [self awaitExpectations];

    // Test that all events are in the array:
    XCTAssert([BranchEvent standardEvents].count == 16);
}

@end
