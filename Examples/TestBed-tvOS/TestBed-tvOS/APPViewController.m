//
//  APPViewController.m
//  TestBed-tvOS
//
//  Created by Edward Smith on 8/1/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPViewController.h"
#import "APPAppDelegate.h"
#import <Branch/Branch.h>
#import "../../../Branch/BNCApplication.h"
#import "../../../Branch/BranchMainClass+Private.h"

@interface APPViewController ()
        <UITableViewDelegate,
         UITableViewDataSource,
         UITextViewDelegate>
@property (weak) IBOutlet UITableView *tableView;
@property (strong) NSArray<NSDictionary*> *tableItems;
@end

#pragma mark - APPViewController

@implementation APPViewController

- (void) configureTextView:(APPTextView*)textView placeholder:(NSString*)placeholder {
    textView.delegate = self;
    textView.placeholderLabel.text = placeholder;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.tableItems = @[@{
            @"title":       @"Tracking Disabled",
            @"detail":      @"Disable user tracking.",
            @"selector":    @"disableTrackingAction:"
        },@{
            @"title":       @"Limit Facebook",
            @"detail":      @"Limit Facebook user tracking.",
            @"selector":    @"limitFacebookTrackingAction:"
        },@{
            @"title":       @"Show Configuration",
            @"detail":      @"Show the current Branch configuration.",
            @"selector":    @"showConfiguration:",
        },@{
            @"title":       @"Set Identity",
            @"detail":      @"Set the current user's identity to a developer friendly value.",
            @"selector":    @"setIdentity:",
        },@{
            @"title":       @"Log User Out",
            @"detail":      @"Log the current user out.",
            @"selector":    @"logUserOut:",
        },@{
            @"title":       @"Purchase Event",
            @"detail":      @"Send a v2-purchase event.",
            @"selector":    @"sendPurchaseEvent:",
        },@{
            @"title":       @"Create Short Link",
            @"detail":      @"Create a Branch short link.",
            @"selector":    @"createShortLink:",
        },@{
            @"title":       @"Create Long Link",
            @"detail":      @"Create a Branch long link.",
            @"selector":    @"createLongLink:",
        },@{
            @"title":       @"Open Last Link",
            @"detail":      @"Open the link the was just created.",
            @"selector":    @"openLink:",
        },
    ];

    [self configureTextView:self.dataTextView placeholder:@"< Data >"];
    [self configureTextView:self.requestTextView placeholder:@"< Request >"];
    [self configureTextView:self.responseTextView placeholder:@"< Response >"];
    ((APPAppDelegate*)[UIApplication sharedApplication].delegate).viewController = self;
}

- (void) clearUIFields {
    self.stateField.text = @"";
    self.urlField.text = @"";
    self.errorField.text = @"";
    self.dataTextView.text = @"";
    self.requestTextView.text = @"";
    self.responseTextView.text = @"";
}

- (NSString*) errorMessage:(NSError*)error {
    if (error) {
        NSString*a = error.localizedDescription ?: @"";
        NSString*b = error.localizedFailureReason ?: @"";
        return [NSString stringWithFormat:@"%@ %@", a, b];
    }
    return @"< None >";
}

- (void) textViewWasSelected:(APPTextView*)textView {
    [UIView animateWithDuration:0.10 animations:^{
        if (textView.isSelected) {
            for (UITextView* tv in self.stackView.arrangedSubviews) {
                if (tv != textView) [tv removeFromSuperview];
            }
            textView.scrollEnabled = YES;
            textView.clipsToBounds = YES;
        } else {
            textView.scrollEnabled = NO;
            textView.clipsToBounds = NO;
            [self.stackView insertArrangedSubview:self.dataTextView atIndex:0];
            [self.stackView insertArrangedSubview:self.requestTextView atIndex:1];
            [self.stackView insertArrangedSubview:self.responseTextView atIndex:2];
        }
        [self.stackView setNeedsLayout];
        [self.stackView layoutIfNeeded];
    }];
}

#pragma mark - Action Item Collection

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     return self.tableItems.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell*cell = [self.tableView dequeueReusableCellWithIdentifier:@"kCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"kCell"];
    }
    NSDictionary*d = self.tableItems[indexPath.item];
    cell.textLabel.text = d[@"title"];
    NSString*value = @"";
    switch (indexPath.row) {
    case 0:
        value = [Branch sharedInstance].trackingDisabled ? @"True" : @"False";
        break;
    case 1:
        value = [Branch sharedInstance].limitFacebookTracking ? @"True" : @"False";
        break;
    default:
        break;
    }
    cell.detailTextLabel.text = value;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString*s = self.tableItems[indexPath.item][@"selector"];
    if (!s) return;
    SEL selector = NSSelectorFromString(s);
    [self performSelectorOnMainThread:selector withObject:self waitUntilDone:NO];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction) showConfiguration:(id)sender {
    [self clearUIFields];
    BranchConfiguration*configuration = [Branch sharedInstance].configuration;
    NSString*string =
        [NSString stringWithFormat:@"      Key: %@\n  Server: %@\n Service: %@\nScheme: %@",
            configuration.key,
            configuration.branchAPIServiceURL,
            configuration.networkServiceClass,
            [BNCApplication currentApplication].defaultURLScheme];
    self.dataTextView.text = string;
}

- (IBAction) setIdentity:(id)sender {
    [self clearUIFields];
    [[Branch sharedInstance] setUserIdentity:@"Bob" completion:^ (BranchSession*session, NSError*error) {
        self.stateField.text =
            [NSString stringWithFormat:@"Set Identity: '%@'", session.userIdentityForDeveloper];
        self.errorField.text = [self errorMessage:error];
    }];
}

- (IBAction) logUserOut:(id)sender {
    BNCLogMethodName();
    [self clearUIFields];
    [[Branch sharedInstance] logoutWithCompletion:^ (NSError*error) {
        self.stateField.text = @"Log User Out";
        self.errorField.text = [self errorMessage:error];
    }];
}

- (IBAction) sendPurchaseEvent:(id)sender {
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
    event.contentItems = (NSMutableArray*) @[ buo ];
    [self clearUIFields];
    [[Branch sharedInstance] logEvent:event completion:^(NSError * _Nullable error) {
        self.stateField.text = event.eventName;
        self.errorField.text = (error) ? error.localizedDescription : @"< None >";
    }];
}

- (BranchUniversalObject*) createUniversalObject {
    NSString *canonicalIdentifier = @"item/12345";
    NSString *canonicalUrl = @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/";
    NSString *contentTitle = @"Content Title";
    NSString *contentDescription = @"My Content Description";
    NSString *imageUrl =
        @"http://a57.foxnews.com/images.foxnews.com/content/fox-news/science/2018/03/20/"
         "first-day-spring-arrives-5-things-to-know-about-vernal-equinox/_jcr_content/"
         "par/featured_image/media-0.img.jpg/1862/1048/1521552912093.jpg?ve=1&tl=1";

    BranchUniversalObject *buo =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier:canonicalIdentifier];
    buo.canonicalUrl = canonicalUrl;
    buo.title = contentTitle;
    buo.contentDescription = contentDescription;
    buo.imageUrl = imageUrl;
    buo.contentMetadata.price = [NSDecimalNumber decimalNumberWithString:@"1000.00"];
    buo.contentMetadata.currency = @"$";
    buo.contentMetadata.contentSchema = BranchContentSchemaTextArticle;
    buo.contentMetadata.customMetadata[@"deeplink_text"] =
        [NSString stringWithFormat:
            @"This text was embedded as data in a Branch link with the following characteristics:\n\n"
             "canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n",
                canonicalUrl, contentTitle, contentDescription, imageUrl];
    return buo;
}

- (BranchLinkProperties*) createLinkProperties {
    NSString *feature = @"Sharing Feature";
    NSString *channel = @"Distribution Channel";
//    NSString *desktop_url = @"http://branch.io";
//    NSString *ios_url = @"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/";

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.tags = @[ @"tag1", @"tag2" ];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.stage = @"stage four";
    linkProperties.campaign = @"some campaign";
    linkProperties.matchDuration = 18000;
    // TODO: Control params:
//    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
//    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    return linkProperties;
}

static NSURL*lastCreatedLink = nil;

- (IBAction) createShortLink:(id)sender {
    [self clearUIFields];
    BranchLinkProperties *linkProperties = [self createLinkProperties];
    BranchUniversalObject *buo = [self createUniversalObject];
    buo.creationDate = [NSDate date];
    [[Branch sharedInstance]
        branchShortLinkWithContent:buo
        linkProperties:linkProperties
        completion:^(NSURL * _Nullable shortURL, NSError * _Nullable error) {
            self.errorField.text = [self errorMessage:error];
            self.dataTextView.text = shortURL.absoluteString ?: @"";
            lastCreatedLink = shortURL;
        }];
}

- (IBAction) createLongLink:(id)sender {
    [self clearUIFields];
    BranchLinkProperties *linkProperties = [self createLinkProperties];
    BranchUniversalObject *buo = [self createUniversalObject];
    buo.creationDate = [NSDate date];
    NSURL*url = [[Branch sharedInstance] branchLongLinkWithContent:buo linkProperties:linkProperties];
    self.errorField.text = [self errorMessage:nil];
    self.dataTextView.text = url.absoluteString;
    lastCreatedLink = url;
}

- (IBAction) openLink:(id)sender {
    [[Branch sharedInstance] openURL:lastCreatedLink];
}


- (IBAction)disableTrackingAction:(id)sender {
    [Branch sharedInstance].trackingDisabled = ![Branch sharedInstance].trackingDisabled;
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
        withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)limitFacebookTrackingAction:(id)sender {
    [Branch sharedInstance].limitFacebookTracking = ![Branch sharedInstance].limitFacebookTracking;
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:1 inSection:0] ]
        withRowAnimation:UITableViewRowAnimationNone];
}

@end
