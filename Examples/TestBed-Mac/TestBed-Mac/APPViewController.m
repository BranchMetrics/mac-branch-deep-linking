//
//  APPViewController.m
//  TestBed-Mac
//
//  Created by Edward Smith on 5/15/18.
//  Copyright © 2018 Edward Smith. All rights reserved.
//

#import "APPViewController.h"
#import "APPActionItemView.h"
#import <Branch/Branch.h>

#pragma mark APPViewController

@interface APPViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource>
@property (weak) IBOutlet NSCollectionView *actionItemCollection;
@property (strong) NSArray<NSDictionary*> *actionItems;
@end

@implementation APPViewController

+ (APPViewController*) loadController {
    APPViewController*controller = [[APPViewController alloc] init];
    BOOL loaded =
        [[NSBundle mainBundle]
            loadNibNamed:NSStringFromClass(self)
            owner:controller
            topLevelObjects:nil];
    return (loaded) ? controller : nil;
}

- (void) awakeFromNib {
    self.actionItems = @[@{
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
        }
    ];
    NSNib*nib = [[NSNib alloc] initWithNibNamed:@"APPActionItemView" bundle:[NSBundle mainBundle]];
    [self.actionItemCollection registerNib:nib
        forItemWithIdentifier:NSStringFromClass(APPActionItemView.class)];
}

- (void) clearUIFields {
    self.stateField.stringValue = @"";
    self.urlField.stringValue = @"";
    self.errorField.stringValue = @"";
    self.dataField.stringValue = @"";
}

#pragma mark - Action Item Collection

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
     return self.actionItems.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
    itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    APPActionItemView*view =
        [self.actionItemCollection makeItemWithIdentifier:NSStringFromClass(APPActionItemView.class)
            forIndexPath:indexPath];
    NSDictionary*d = self.actionItems[indexPath.item];
    view.textField.stringValue = d[@"title"];
    view.detailTextField.stringValue = d[@"detail"];
    return view;
}

- (void)collectionView:(NSCollectionView *)collectionView
didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSIndexPath*indexPath = [indexPaths anyObject];
    if (!indexPath) return;
    NSString*s = self.actionItems[indexPath.item][@"selector"];
    if (!s) return;
    SEL selector = NSSelectorFromString(s);
    [self performSelectorOnMainThread:selector withObject:self waitUntilDone:NO];
    [self.actionItemCollection deselectAll:nil];
}

#pragma mark - Actions

- (void) setIdentity:(id)sender {
    [[Branch sharedInstance] setIdentity:@"Bob" callback:^ (NSError*error) {
        [self clearUIFields];
        self.stateField.stringValue = @"Set Identity: 'Bob'";
        self.errorField.stringValue = (error) ? error.localizedDescription : @"< None >";
    }];
}

- (void) logUserOut:(id)sender {
    BNCLogMethodName();
    [[Branch sharedInstance] logoutWithCallback:^ (NSError*error) {
        [self clearUIFields];
        self.stateField.stringValue = @"Log User Out";
        self.errorField.stringValue = (error) ? error.localizedDescription : @"< None >";
    }];
}

- (void) sendPurchaseEvent:(id)sender {
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
    [event logEventWithCompletion:^(NSError * _Nullable error) {
        [self clearUIFields];
        self.stateField.stringValue = event.eventName;
        self.errorField.stringValue = (error) ? error.localizedDescription : @"< None >";
    }];
}

@end
