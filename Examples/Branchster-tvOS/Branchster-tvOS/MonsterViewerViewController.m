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

@interface MonsterViewerViewController () <NSUserActivityDelegate>
@property (weak, nonatomic) IBOutlet UIView      *botLayerOneColor;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerTwoBody;
@property (weak, nonatomic) IBOutlet UIImageView *botLayerThreeFace;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtDescription;
@property (weak, nonatomic) IBOutlet UIButton    *cmdShare;
@property (weak, nonatomic) IBOutlet UIButton    *cmdInfo;
@property (weak, nonatomic) IBOutlet UITextView  *shareTextView;

@property (strong) NSURL*monsterURL;
@property (strong) NSDictionary*monsterDictionary;
@property (strong) NSUserActivity*activity;
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
    [self.botLayerOneColor setBackgroundColor:[MonsterPartsFactory colorForIndex:[self.monster colorIndex]]];
    [self.botLayerTwoBody setImage:[MonsterPartsFactory imageForBody:[self.monster bodyIndex]]];
    [self.botLayerThreeFace setImage:[MonsterPartsFactory imageForFace:[self.monster faceIndex]]];

    self.txtName.text = self.monster.monsterName;
    self.txtDescription.text = self.monster.monsterDescription;
    self.cmdShare.backgroundColor = [MonsterPartsFactory colorForIndex:5];
    self.cmdInfo.backgroundColor = [MonsterPartsFactory colorForIndex:5];
/*
    [self.monster registerViewWithCallback:^(NSDictionary *params, NSError *error) {
        NSLog(@"Monster %@ was viewed.  params: %@", self.monster.monsterName, params);
    }];
*/
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

- (IBAction)cmdChangeClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)shareAction:(id)sender {
/*
    UIActivityItem*item = [[UIActivityItem alloc] init];

    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Open Failed"
            message:[NSString stringWithFormat:@"Can't open the URL '%@'.", URL.absoluteString]
            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction*defaultAction =
        [UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
*/
}

- (void) publishUserActivityURL:(NSURL*)URL {
    self.monsterURL = URL;
    self.activity = [[NSUserActivity alloc] initWithActivityType:@"io.branch.Branchster"];
    self.activity.title = self.monster.monsterName;
    self.activity.keywords = [NSSet setWithArray:@[ @"Branch", @"Monster", @"Factory" ]];
    self.activity.requiredUserInfoKeys = [NSSet setWithArray:@[ @"branch" ]];
//    self.activity.userInfo = @{ @"branch": URL };
    [self.activity addUserInfoEntriesFromDictionary:@{ @"branch": URL }];
    self.activity.eligibleForSearch = YES;
    self.activity.eligibleForHandoff = YES;
    self.activity.eligibleForPublicIndexing = YES;
//  self.activity.webpageURL = URL;
// iOS Only:
//    self.activity.eligibleForPrediction = YES;
//    self.activity.suggestedInvocationPhrase = @"Show Monster";
    self.activity.delegate = self;
    self.userActivity = self.activity;
    [self.userActivity becomeCurrent];
//  [self.userActivity needsSave];
}

- (void)userActivityWasContinued:(NSUserActivity *)userActivity {
    BNCLogMethodName();
    BNCLogDebug(@"%@", userActivity.userInfo);
}

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    BNCLogMethodName();
    BNCLogDebug(@"before userInfo %@", userActivity.userInfo);
    [userActivity addUserInfoEntriesFromDictionary:@{ @"branch": self.monsterURL }];
    BNCLogDebug(@" after userInfo %@", userActivity.userInfo);
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

@end
