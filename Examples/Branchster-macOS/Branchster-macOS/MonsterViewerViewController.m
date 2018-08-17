//
//  MonsterViewerViewController.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

@import Branch;
#import "BranchUniversalObject+MonsterHelpers.h"
#import "BranchInfoViewController.h"
#import "MonsterViewerViewController.h"
#import "MonsterPartsFactory.h"

@interface MonsterViewerViewController () // <UITextViewDelegate>

@property (strong, nonatomic) NSDictionary *monsterMetadata;

@property (weak, nonatomic) IBOutlet NSView *botLayerOneColor;
@property (weak, nonatomic) IBOutlet NSImageView *botLayerTwoBody;
@property (weak, nonatomic) IBOutlet NSImageView *botLayerThreeFace;
@property (weak, nonatomic) IBOutlet NSTextField *txtName;
@property (weak, nonatomic) IBOutlet NSTextField *txtDescription;

@property (weak, nonatomic) IBOutlet NSButton *cmdChange;
@property (weak, nonatomic) IBOutlet NSButton *cmdInfo;

@property (strong, nonatomic) IBOutlet NSTextView *shareTextView;
@property NSString *shareURL;
@end

#pragma mark - MonsterViewerViewController

@implementation MonsterViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.cmdChange.layer setCornerRadius:3.0];
    [self.cmdInfo.layer setCornerRadius:3.0];
}

- (void) viewWillAppear {
    [super viewWillAppear];
    [self updateView];
}

- (void) updateView {
    self.botLayerOneColor.layer.backgroundColor =
        [MonsterPartsFactory colorForIndex:[self.monster colorIndex]].CGColor;
    [self.botLayerTwoBody setImage:[MonsterPartsFactory imageForBody:[self.monster bodyIndex]]];
    [self.botLayerThreeFace setImage:[MonsterPartsFactory imageForFace:[self.monster faceIndex]]];

    self.txtName.stringValue = self.monster. monsterName;
    self.txtDescription.stringValue = self.monster.monsterDescription;

    /*
    NSInteger priceInt = arc4random_uniform(4) + 1;
    NSString *priceString = [NSString stringWithFormat:@"%1.2f", (float)priceInt];
    _price = [NSDecimalNumber decimalNumberWithString:priceString];
    */


    self.monsterMetadata = @{
        @"color_index":     @([self.monster colorIndex]),
        @"body_index":      @([self.monster bodyIndex]),
        @"face_index":      @([self.monster faceIndex]),
        @"monster_name":    self.monster.monsterName
    };

/*
    [self.monster registerViewWithCallback:^(NSDictionary *params, NSError *error) {
        NSLog(@"Monster %@ was viewed.  params: %@", self.monster.monsterName, params);
    }];
*/
}

- (void) viewDidAppear {
    [super viewDidAppear];
/*
    [[Branch getInstance] userCompletedAction:@"Product View" withState:@{
        @"sku":      self.monsterName,
        @"price":    self.price,
        @"currency": @"USD"
    }];
    BranchUniversalObject*buo = [[BranchUniversalObject alloc] initWithTitle:self.monsterName];
    [Branch.sharedInstance logEvent:event];
*/
}

- (void) updateMonsterMetaData {

    //and every time it gets set, I need to create a new url
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"monster_sharing";
    linkProperties.channel = @"twitter";

    self.monster.title = [NSString stringWithFormat:@"My Branchster: %@", self.monster.monsterName];
    self.monster.contentDescription = self.monster.monsterDescription;
    self.monster.imageUrl =
        [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png",
            (short)[self.monster colorIndex],
            (short)[self.monster bodyIndex],
            (short)[self.monster faceIndex]];
//    [self.monster getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
//        if (!error) {
//            self.shareURL = url;
//            NSLog(@"new monster url created:  %@", self.shareURL);
//            self.shareTextView.text = url;
//        }
//    }];
}

/*
-(IBAction)shareSheet:(id)sender {
    if (self.monsterName.length <= 0) self.monsterName = @"Nameless Monster";

    BNCCommerceEvent *commerceEvent = [[BNCCommerceEvent alloc] init];
    commerceEvent.revenue = self.price;
    commerceEvent.currency = @"USD";

    BranchUniversalObject*buo = [[BranchUniversalObject alloc] initWithTitle:self.monsterName];
    buo.contentMetadata.sku = self.monsterName;
    buo.contentMetadata.price = self.price;
    buo.contentMetadata.quantity = 1.0;
    buo.contentMetadata.variant = @"X-Tra Hairy";
    buo.contentMetadata.brand = @"Branch";
    buo.category = BNCProductCategoryAnimalSupplies;
    buo.contentMetadata.name = self.monsterName;

    BranchEvent*event = [BranchEvent standardEvent:BranchStandardEventAddToCart];

    [[Branch getInstance] userCompletedAction:BNCAddToCartEvent withState:@{
        @"sku":      self.monsterName,
        @"price":    self.price,
        @"currency": @"USD"
    }];

    [self.monster
        showShareSheetWithShareText:@"Share Your Monster!"
        completion:^(NSString * _Nullable activityType, BOOL completed) {
            if (completed) {
               // [[Branch getInstance] userCompletedAction:BNCAddToCartEvent];
                [[Branch getInstance] sendCommerceEvent:commerceEvent
                                               metadata:nil
                                         withCompletion:^ (NSDictionary *response, NSError *error) {
                                             if (error) {  }
                                         }];
            }
        }];
    
    [UIMenuController sharedMenuController].menuVisible = NO;
    [self.shareTextView resignFirstResponder];
}
*/

- (IBAction)cmdChangeClick:(id)sender {
    [NSApplication.sharedApplication sendAction:@selector(editMonster:) to:nil from:self];
}


- (NSDictionary*) facebookDictionaryWithURL:(NSURL*)URL {
    NSMutableDictionary*dictionary = [NSMutableDictionary new];
    dictionary[@"name"] = [NSString stringWithFormat:@"My Branchster] =%@", self.monster.monsterName];
    dictionary[@"caption"] = self.monster.monsterDescription;
    dictionary[@"description"] = self.monster.monsterDescription;
    dictionary[@"link"] = URL.absoluteString;
    dictionary[@"picture"] =
        [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png",
            (short)self.monster.colorIndex, (short)self.monster.bodyIndex, (short)self.monster.faceIndex];
    return dictionary;
}

/*
// This function serves to dynamically generate the dictionary parameters to embed in the Branch link
// These are the parameters that will be available in the callback of init user session if
// a user clicked the link and was deep linked
- (NSDictionary *)prepareBranchDict {
    return [[NSDictionary alloc] initWithObjects:@[
                                                  [NSNumber numberWithInteger:[self.monster colorIndex]],
                                                  [NSNumber numberWithInteger:[self.monster bodyIndex]],
                                                  [NSNumber numberWithInteger:[self.monster faceIndex]],
                                                  self.monsterName,
                                                  @"true",
                                                  [NSString stringWithFormat:@"My Branchster: %@", self.monsterName],
                                                  self.monsterDescription,
                                                  [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png", (short)[self.monster colorIndex], (short)[self.monster bodyIndex], (short)[self.monster faceIndex]]]
                                        forKeys:@[
                                                  @"color_index",
                                                  @"body_index",
                                                  @"face_index",
                                                  @"monster_name",
                                                  @"monster",
                                                  @"$og_title",
                                                  @"$og_description",
                                                  @"$og_image_url"]];
}
*/

/*
- (void)viewDidLayoutSubviews {
    [self adjustMonsterPicturesForScreenSize];
}

- (void)adjustMonsterPicturesForScreenSize {
    [self.botLayerOneColor setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.botLayerTwoBody setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.botLayerThreeFace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.txtDescription setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.cmdChange setTranslatesAutoresizingMaskIntoConstraints:NO];

    CGRect screenSize = [[UIScreen mainScreen] bounds];
    CGFloat widthRatio = self.botLayerOneColor.frame.size.width/self.botLayerOneColor.frame.size.height;
    CGFloat newHeight = screenSize.size.height;
        newHeight = newHeight * MONSTER_HEIGHT;
    CGFloat newWidth = widthRatio * newHeight;
    CGRect newFrame = CGRectMake(
        (screenSize.size.width-newWidth)/2,
        self.botLayerOneColor.frame.origin.y,
        newWidth,
        newHeight
    );
    
    self.botLayerOneColor.frame = newFrame;
    self.botLayerTwoBody.frame = newFrame;
    self.botLayerThreeFace.frame = newFrame;
    
    CGRect textFrame = self.txtDescription.frame;
    textFrame.origin.y  = newFrame.origin.y + newFrame.size.height + 8;
    self.txtDescription.frame = textFrame;
    
    CGRect cmdFrame = self.cmdChange.frame;
        cmdFrame.origin.x = newFrame.origin.x + newFrame.size.width;
    self.cmdChange.frame = cmdFrame;
    [self.view layoutSubviews];
}
*/

@end
