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
#import "MonsterWindowController.h"

@interface MonsterViewerViewController () <NSSharingServicePickerDelegate, NSUserActivityDelegate>

@property (weak, nonatomic) IBOutlet NSView      *botLayerOneColor;
@property (weak, nonatomic) IBOutlet NSImageView *botLayerTwoBody;
@property (weak, nonatomic) IBOutlet NSImageView *botLayerThreeFace;
@property (weak, nonatomic) IBOutlet NSTextField *txtName;
@property (weak, nonatomic) IBOutlet NSTextField *txtURL;
@property (weak, nonatomic) IBOutlet NSTextField *txtDescription;
@property (weak, nonatomic) IBOutlet NSTextField *shareTextField;
@property (weak, nonatomic) IBOutlet NSButton    *shareButton;
@property (weak, nonatomic) IBOutlet NSButton    *cmdChange;
@property (weak, nonatomic) IBOutlet NSButton    *cmdInfo;

@property (strong) NSURL*monsterURL;
@property (strong) NSDictionary*monsterDictionary;
@property (strong) NSUserActivity*activity;
@end

#pragma mark - MonsterViewerViewController

@implementation MonsterViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.cmdChange.layer setCornerRadius:3.0];
    [self.cmdInfo.layer setCornerRadius:3.0];
    self.shareButton.image = [NSImage imageNamed:NSImageNameShareTemplate];
    CGSize s = self.shareButton.image.size;
    s.height *= 1.4f;
    s.width *= 1.4f;
    self.shareButton.image.size = s;
    self.shareButton.layer.borderWidth = 1.5f;
    self.shareButton.layer.borderColor = [NSColor lightGrayColor].CGColor;
    CGRect r = self.shareButton.bounds;
    self.shareButton.layer.cornerRadius = r.size.height / 2.0;
    [self.shareButton sendActionOn:NSLeftMouseDownMask];
    self.shareTextField.stringValue = @"";
}

- (void) viewWillAppear {
    [super viewWillAppear];
    [self updateView];
    [self updateMonster];
    /*
    [self.monster registerViewWithCallback:^(NSDictionary *params, NSError *error) {
        NSLog(@"Monster %@ was viewed.  params: %@", self.monster.monsterName, params);
    }];
    */
}

- (void) updateView {
    self.botLayerOneColor.layer.backgroundColor =
        [MonsterPartsFactory colorForIndex:[self.monster colorIndex]].CGColor;
    [self.botLayerTwoBody setImage:[MonsterPartsFactory imageForBody:[self.monster bodyIndex]]];
    [self.botLayerThreeFace setImage:[MonsterPartsFactory imageForFace:[self.monster faceIndex]]];
    self.txtName.stringValue = self.monster. monsterName;
    self.txtDescription.stringValue = self.monster.monsterDescription;
    self.shareTextField.stringValue = self.monsterURL ? self.monsterURL.absoluteString : @"";
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

- (IBAction)cmdChangeClick:(id)sender {
    [NSApplication.sharedApplication sendAction:@selector(editMonster:) to:nil from:self];
}

- (void) updateMonster {
    if (self.monster == nil || !self.monster.isMonster) return;
    self.monsterDictionary = @{
        @"color_index": @(self.monster.colorIndex),
        @"body_index":  @(self.monster.bodyIndex),
        @"face_index":  @(self.monster.faceIndex),
        @"monster_name":self.monster.monsterName
    };
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"monster_sharing";
    linkProperties.channel = @"Branch Monster Factory";
    self.monster.title = [NSString stringWithFormat:@"My Branchster: %@", self.monster.monsterName];
    self.monster.contentDescription = self.monster.monsterDescription;
    self.monster.imageUrl =
        [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/branchmonsterfactory/%hd%hd%hd.png",
            (short)self.monster.colorIndex,
            (short)self.monster.bodyIndex,
            (short)self.monster.faceIndex];
    self.monsterURL = nil;
    self.shareTextField.stringValue = @"";
    [Branch.sharedInstance
        branchShortLinkWithContent:self.monster
                     linkProperties:linkProperties
                         completion:^ (NSURL*_Nullable shortURL, NSError*_Nullable error) {
            if (error || shortURL == nil) {
                NSString *message = error.localizedDescription;
                if (message.length <= 0) message = @"No link returned.";
                NSAlert*alert = [[NSAlert alloc] init];
                alert.messageText = @"Can't Create Link";
                alert.informativeText = message;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                return;
            }
            self.monsterURL = shortURL;
            self.shareTextField.stringValue = shortURL.absoluteString;
            [self publishUserActivityURL:shortURL];
        }];
}

- (IBAction) showShareSheetAction:(id)sender {
    if (!self.monsterURL) return;
    NSMutableArray*items = [NSMutableArray new];
    if (self.monster.title.length) [items addObject:self.monster.title];
    [items addObject:self.monsterURL];
    NSSharingServicePicker *sharingServicePicker =
        [[NSSharingServicePicker alloc] initWithItems:items];
    sharingServicePicker.delegate = self;
    [sharingServicePicker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
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

@end
