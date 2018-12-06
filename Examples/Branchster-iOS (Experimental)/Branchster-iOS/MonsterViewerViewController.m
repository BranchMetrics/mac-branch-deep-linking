//
//  MonsterViewerViewController.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

@import MessageUI;
@import Social;
@import Branch;
#import "BranchUniversalObject+MonsterHelpers.h"
#import "BranchInfoViewController.h"
#import "MonsterViewerViewController.h"
#import "MonsterPartsFactory.h"

@interface MonsterViewerViewController () /*<UITextViewDelegate>*/

@property (strong, nonatomic) NSString *monsterName;
@property (strong, nonatomic) NSString *monsterDescription;
@property (strong, nonatomic) NSDecimalNumber *price;

@property (weak, nonatomic) IBOutlet UIView *botLayerOneColor;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerTwoBody;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerThreeFace;
@property (weak, nonatomic) IBOutlet UILabel *txtName;
@property (weak, nonatomic) IBOutlet UILabel *txtDescription;

@property (weak, nonatomic) IBOutlet UIButton *cmdChange;
@property (weak, nonatomic) IBOutlet UIButton *cmdInfo;

@property (weak, nonatomic) IBOutlet UITextView *shareTextView;

@property (strong) NSURL*monsterURL;
@property (strong) NSDictionary*monsterDictionary;
@property (strong) NSUserActivity*activity;
@end

#pragma mark - MonsterViewerViewController

@implementation MonsterViewerViewController

static CGFloat MONSTER_HEIGHT = 0.4f;

+ (MonsterViewerViewController*) viewControllerWithMonster:(BranchUniversalObject*)monster {
    UIStoryboard*storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MonsterViewerViewController*controller =
        [storyBoard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
    controller.monster = monster;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.botLayerOneColor setBackgroundColor:[MonsterPartsFactory colorForIndex:self.monster.colorIndex]];
    [self.botLayerTwoBody setImage:[MonsterPartsFactory imageForBody:self.monster.bodyIndex]];
    [self.botLayerThreeFace setImage:[MonsterPartsFactory imageForFace:self.monster.faceIndex]];
    
    self.monsterName = self.monster.monsterName;
    if (!self.monsterName) self.monsterName = @"None";

    NSInteger priceInt = arc4random_uniform(4) + 1;
    NSString *priceString = [NSString stringWithFormat:@"%1.2f", (float)priceInt];
    _price = [NSDecimalNumber decimalNumberWithString:priceString];

    self.monsterDescription = self.monster.monsterDescription;
    
    [self.txtName setText:self.monsterName];
    [self.txtDescription setText:self.monsterDescription];

    [self.cmdChange.layer setCornerRadius:3.0];
    [self.cmdInfo.layer setCornerRadius:3.0];
    
//    [self.monster registerViewWithCallback:^(NSDictionary *params, NSError *error) {
//        NSLog(@"Monster %@ was viewed.  params: %@", self.viewingMonster.getMonsterName, params);
//    }];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

- (void) setMonster:(BranchUniversalObject *)monster {
    _monster = monster;
    self.monsterDictionary = @{
        @"color_index": @(self.monster.colorIndex),
        @"body_index":  @(self.monster.bodyIndex),
        @"face_index":  @(self.monster.faceIndex),
        @"monster_name":self.monster.monsterName
    };
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"monster_sharing";
    linkProperties.channel = @"Branch Monster Factory";
    monster.title = [NSString stringWithFormat:@"My Branchster: %@", self.monster.monsterName];
    monster.contentDescription = self.monster.monsterDescription;
    monster.imageUrl =
        [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png",
            (short)self.monster.colorIndex,
            (short)self.monster.bodyIndex,
            (short)self.monster.faceIndex];
    [Branch.sharedInstance
        branchShortLinkWithContent:self.monster
                     linkProperties:linkProperties
                         completion:^ (NSURL*_Nullable shortURL, NSError*_Nullable error) {
            if (error || shortURL == nil) {
                NSString *message = error.localizedDescription;
                if (message.length <= 0) message = @"No link returned.";
                UIAlertController* alert =
                    [UIAlertController alertControllerWithTitle:@"Can't Create a Short Link"
                        message:message
                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction*defaultAction =
                    [UIAlertAction actionWithTitle:@"OK"
                        style:UIAlertActionStyleDefault
                        handler:nil];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            self.monsterURL = shortURL;
            [self publishUserActivityURL:shortURL];
        }];
}

// https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/Handoff/AdoptingHandoff/AdoptingHandoff.html

- (void) publishUserActivityURL:(NSURL*)URL {
    __auto_type activity = [[NSUserActivity alloc] initWithActivityType:@"io.branch.Branchster"];
    activity.title = self.monster.monsterName;
    activity.keywords = [NSSet setWithArray:@[ @"Branch", @"Monster", @"Factory" ]];
    activity.userInfo = @{ @"branch": URL };
    activity.eligibleForSearch = YES;
    activity.eligibleForHandoff = YES;
    activity.eligibleForPublicIndexing = YES;
//    self.activity.webpageURL = URL;
// iOS Only:
//    self.activity.eligibleForPrediction = YES;
//    self.activity.suggestedInvocationPhrase = @"Show Monster";
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
}

-(IBAction)shareSheet:(id)sender {
/*
    BNCCommerceEvent *commerceEvent = [[BNCCommerceEvent alloc] init];
    commerceEvent.revenue = self.price;
    commerceEvent.currency = @"USD";

    BNCProduct* branchester = [BNCProduct new];
    if (self.monsterName.length <= 0) self.monsterName = @"Nameless Monster";
    branchester.sku = self.monsterName;
    branchester.price = self.price;
    branchester.quantity = @1;
    branchester.variant = @"X-Tra Hairy";
    branchester.brand = @"Branch";
    branchester.category = BNCProductCategoryAnimalSupplies;
    branchester.name = self.monsterName;
    commerceEvent.products = [NSArray arrayWithObject:branchester];
    
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
*/
}


-(IBAction)copyShareURL:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.shareTextView.text;
}


- (IBAction)cmdChangeClick:(id)sender {
        [self.navigationController popViewControllerAnimated:YES];
}

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

@end
