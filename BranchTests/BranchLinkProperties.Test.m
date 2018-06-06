/**
 @file          BranchLinkProperties.Test.m
 @package       BranchTests
 @brief         BranchLinkProperties tests.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BranchLinkProperties.h"
#import "BNCWireFormat.h"

@interface BranchLinkPropertiesTest : BNCTestCase
@end

@implementation BranchLinkPropertiesTest

- (void) testSerializeDeserialize {
    NSDictionary* open = [self mutableDictionaryFromBundleJSONWithKey:@"BranchOpenResponse"];
    XCTAssertNotNil(open);
    NSDictionary*d1 = BNCDictionaryFromWireFormat(open[@"data"]);
    BranchLinkProperties *lp = [BranchLinkProperties linkPropertiesWithDictionary:d1];
    NSArray*tags = @[ @"tag1", @"tag2" ];
    XCTAssertEqualObjects(lp.tags, tags);
    XCTAssertEqualObjects(lp.feature, @"Sharing Feature");
    XCTAssertEqualObjects(lp.alias, nil);
    XCTAssertEqualObjects(lp.channel, @"Distribution Channel");
    XCTAssertEqualObjects(lp.stage, @"stage four");
    XCTAssertEqualObjects(lp.campaign, @"some campaign");
    XCTAssertEqual(lp.matchDuration, 0);
    NSDictionary*cp = @{
        @"$canonical_identifier": @"item/12345",
        @"$canonical_url": @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/",
        @"$content_schema": @"some type",
        @"$creation_timestamp": @1527379945531,
        @"$currency": @"$",
        @"$desktop_url": @"http://branch.io",
        @"$identity_id": @529056271991951584,
        @"$ios_url":@"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/",
        @"$match_duration": @12,
        @"$og_description": @"My Content Description",
        @"$og_image_url": @"http://a57.foxnews.com/images.foxnews.com/content/fox-news/science/2018/03/20/first-day-spring-arrives-5-things-to-know-about-vernal-equinox/_jcr_content/par/featured_image/media-0.img.jpg/1862/1048/1521552912093.jpg?ve=1&tl=1",
        @"$og_title": @"Content Title",
        @"$og_type": @"website",
        @"$one_time_use": @0,
        @"$price": @1000,
    };
    XCTAssertEqualObjects(lp.controlParams, cp);

    NSDictionary*d2 = [lp dictionary];
    for (NSString*key in d2.keyEnumerator) {
        id v1 = d1[key];
        id v2 = d2[key];
        XCTAssertEqualObjects(v1, v2);
    }
}

@end
