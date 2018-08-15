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

@property (strong, nonatomic) NSString *monsterName;
@property (strong, nonatomic) NSString *monsterDescription;
@property (strong, nonatomic) NSDecimalNumber *price;

@property (weak, nonatomic) IBOutlet UIView *botLayerOneColor;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerTwoBody;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerThreeFace;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtDescription;

@property (weak, nonatomic) IBOutlet UIButton *cmdChange;
@property (weak, nonatomic) IBOutlet UIButton *cmdInfo;

@property (weak, nonatomic) IBOutlet UITextView *shareTextView;
@property NSString *shareURL;
@end

#pragma mark - MonsterViewerViewController

@implementation MonsterViewerViewController

+ (MonsterViewerViewController*) viewControllerWithMonster:(BranchUniversalObject*)monster {
    UIStoryboard*storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MonsterViewerViewController*controller =
        [storyBoard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
    controller.monster = monster;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.botLayerOneColor
        setBackgroundColor:[MonsterPartsFactory
        colorForIndex:[self.monster colorIndex]]];
    [self.botLayerTwoBody setImage:[MonsterPartsFactory imageForBody:[self.monster bodyIndex]]];
    [self.botLayerThreeFace setImage:[MonsterPartsFactory imageForFace:[self.monster faceIndex]]];
    
    self.monsterName = [self.monster monsterName];
    if (!self.monsterName) self.monsterName = @"None";

    NSInteger priceInt = arc4random_uniform(4) + 1;
    NSString *priceString = [NSString stringWithFormat:@"%1.2f", (float)priceInt];
    _price = [NSDecimalNumber decimalNumberWithString:priceString];

    self.monsterDescription = [self.monster monsterDescription];
    
    [self.txtName setText:self.monsterName];
    [self.txtDescription setText:self.monsterDescription];
    
    self.monsterMetadata = @{
        @"color_index": @([self.monster colorIndex]),
        @"body_index":  @([self.monster bodyIndex]),
        @"face_index":  @([self.monster faceIndex]),
        @"monster_name":self.monsterName
    };

    [self.cmdChange.layer setCornerRadius:3.0];
    [self.cmdInfo.layer setCornerRadius:3.0];
    
/*
    [self.monster registerViewWithCallback:^(NSDictionary *params, NSError *error) {
        NSLog(@"Monster %@ was viewed.  params: %@", self.monster.monsterName, params);
    }];
*/
    [self setViewingMonster:self.monster];  // Not awesome, but it triggers the setter
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.monsterName.length <= 0) self.monsterName = @"Nameless Monster";
/*
    [[Branch getInstance] userCompletedAction:@"Product View" withState:@{
        @"sku":      self.monsterName,
        @"price":    self.price,
        @"currency": @"USD"
    }];
    BranchUniversalObject*buo = [[BranchUniversalObject alloc] initWithTitle:self.monsterName];
    buo.cate
    [Branch.sharedInstance logEvent:event];
*/
}
-(void) setViewingMonster: (BranchUniversalObject *)monster {
    _monster = monster;
    
    //and every time it gets set, I need to create a new url
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"monster_sharing";
    linkProperties.channel = @"twitter";

    monster.title = [NSString stringWithFormat:@"My Branchster: %@", self.monsterName];
    monster.contentDescription = self.monsterDescription;
    monster.imageUrl =
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
        [self.navigationController popViewControllerAnimated:YES];
}


- (NSDictionary *)prepareFBDict:(NSString *)url {
    return [[NSDictionary alloc] initWithObjects:@[
                                                   [NSString stringWithFormat:@"My Branchster: %@", self.monsterName],
                                                   self.monsterDescription,
                                                   self.monsterDescription,
                                                   url,
                                                   [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png", (short)[self.monster colorIndex], (short)[self.monster bodyIndex], (short)[self.monster faceIndex]]]
                                         forKeys:@[
                                                   @"name",
                                                   @"caption",
                                                   @"description",
                                                   @"link",
                                                   @"picture"]];
}

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
