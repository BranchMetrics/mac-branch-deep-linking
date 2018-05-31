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
        }
    ];
    NSNib*nib = [[NSNib alloc] initWithNibNamed:@"APPActionItemView" bundle:[NSBundle mainBundle]];
    [self.actionItemCollection registerNib:nib
        forItemWithIdentifier:NSStringFromClass(APPActionItemView.class)];
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
    [[Branch sharedInstance] setIdentity:@"Bob" withCallback:nil];
}

- (void) logUserOut:(id)sender {
    BNCLogMethodName();
    [[Branch sharedInstance] logoutWithCallback:^ (NSError*error) {
        NSAlert* alert = [[NSAlert alloc] init];
        if (error) {
            alert.alertStyle = NSCriticalAlertStyle;
            alert.messageText = @"Can't Log Out";
            alert.informativeText = error.localizedDescription;
        } else {
            alert.alertStyle = NSInformationalAlertStyle;
            alert.messageText = @"User Logged Out";
        }
        [alert runModal];
    }];
}

@end
