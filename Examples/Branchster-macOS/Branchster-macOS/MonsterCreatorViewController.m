//
//  MonsterCreatorViewController.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

#import "MonsterCreatorViewController.h"
#import "MonsterPartsFactory.h"
#import "ImageCollectionViewCell.h"
#import "MonsterViewerViewController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
#import "MonsterWindowController.h"
@import Branch;

@interface MonsterCreatorViewController () <NSCollectionViewDataSource, NSCollectionViewDelegate>

@property (weak, nonatomic) IBOutlet NSTextField *monsterNameTextField;
@property (weak, nonatomic) IBOutlet NSView *botViewLayerOne;
@property (weak, nonatomic) IBOutlet NSCollectionView *botViewLayerTwo;
@property (weak, nonatomic) IBOutlet NSCollectionView *botViewLayerThree;
@property (weak, nonatomic) IBOutlet NSStackView *colorStackView;

@property (weak, nonatomic) IBOutlet NSButton *cmdRightArrow;
@property (weak, nonatomic) IBOutlet NSButton *cmdLeftArrow;
@property (weak, nonatomic) IBOutlet NSButton *cmdDownArrow;
@property (weak, nonatomic) IBOutlet NSButton *cmdDone;

@property (nonatomic) NSInteger bodyIndex;
@property (nonatomic) NSInteger faceIndex;
@end

#pragma mark - MonsterCreatorViewController

CGFloat const kBorderWidth = 3.0f;

@implementation MonsterCreatorViewController

- (void)viewWillAppear {
    [super viewWillAppear];

    if (!self.monster)
        self.monster = [BranchUniversalObject newEmptyMonster];

    NSInteger i = 0;
    for (NSButton*button in self.colorStackView.subviews) {
        if (![button isKindOfClass:NSButton.class]) continue;
        button.layer.backgroundColor = [MonsterPartsFactory colorForIndex:i].CGColor;
        if (i == [self.monster colorIndex])
            [button.layer setBorderWidth:kBorderWidth];
        else
            [button.layer setBorderWidth:0.0f];
        button.layer.borderColor = [NSColor colorWithWhite:0.3 alpha:1.0].CGColor;
        button.layer.cornerRadius = button.frame.size.width/2;

        button.action = @selector(cmdColorClick:);
        button.target = self;
        ++i;
    }
        
    self.cmdDone.layer.cornerRadius = 3.0f;
    self.cmdDone.layer.backgroundColor = [MonsterPartsFactory colorForIndex:0].CGColor;
    self.cmdDone.layer.borderColor = NSColor.blackColor.CGColor;
    self.cmdDone.layer.borderWidth = 1.0f;
    
    self.botViewLayerOne.layer.backgroundColor =
        [MonsterPartsFactory colorForIndex:[self.monster colorIndex]].CGColor;
    
    self.botViewLayerTwo.delegate = self;
    self.botViewLayerTwo.dataSource = self;
    [self.botViewLayerTwo registerClass:[ImageCollectionViewCell class] forItemWithIdentifier:@"cell"];
    self.botViewLayerTwo.backgroundColors = @[ NSColor.clearColor ];
    self.botViewLayerTwo.enclosingScrollView.backgroundColor = NSColor.clearColor;

    self.botViewLayerThree.delegate = self;
    self.botViewLayerThree.dataSource = self;
    [self.botViewLayerThree registerClass:[ImageCollectionViewCell class] forItemWithIdentifier:@"cell"];
    self.botViewLayerThree.backgroundColors = @[ NSColor.clearColor ];
    self.botViewLayerThree.enclosingScrollView.backgroundColor = NSColor.clearColor;

    self.monsterNameTextField.stringValue = self.monster.monsterName;
}

- (void) viewDidAppear {
    [super viewDidAppear];
    [self updateBody];
    [self updateFace];
    [self.monsterNameTextField becomeFirstResponder];
}

- (void) updateBody {
    [self.botViewLayerTwo
        scrollToItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:self.bodyIndex inSection:0]]
        scrollPosition:
            NSCollectionViewScrollPositionCenteredHorizontally |
            NSCollectionViewScrollPositionCenteredVertically];
}

- (void) updateFace {
    [self.botViewLayerThree
        scrollToItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:self.faceIndex inSection:0]]
        scrollPosition:
            NSCollectionViewScrollPositionCenteredHorizontally |
            NSCollectionViewScrollPositionCenteredVertically];
}

- (void)viewDidLayoutSubviews {
    self.bodyIndex = [self.monster bodyIndex];
    self.faceIndex = [self.monster faceIndex];
    [self updateBody];
    [self updateFace];
}

- (IBAction)cmdLeftClick:(id)sender {
    self.bodyIndex = self.bodyIndex - 1;
    if (self.bodyIndex == -1)
        self.bodyIndex = [MonsterPartsFactory sizeOfBodyArray] - 1;
    [self.monster setBodyIndex:self.bodyIndex];
    [self updateBody];
}

- (IBAction)cmdRightClick:(id)sender {
    self.bodyIndex = self.bodyIndex + 1;
    if (self.bodyIndex == [MonsterPartsFactory sizeOfBodyArray])
        self.bodyIndex = 0;
    [self.monster setBodyIndex:self.bodyIndex];
    [self updateBody];
}

- (IBAction)cmdUpClick:(id)sender {
    self.faceIndex = self.faceIndex - 1;
    if (self.faceIndex == -1)
        self.faceIndex = [MonsterPartsFactory sizeOfFaceArray] - 1;
    [self.monster setFaceIndex:self.faceIndex];
    [self updateFace];
}

- (IBAction)cmdDownClick:(id)sender {
    self.faceIndex = self.faceIndex + 1;
    if (self.faceIndex == [MonsterPartsFactory sizeOfFaceArray])
        self.faceIndex = 0;
    [self.monster setFaceIndex:self.faceIndex];
    [self updateFace];
}

- (IBAction)cmdColorClick:(id)sender {
    NSButton *currColorButton = (NSButton *)sender;
    int i = 0, selected = 0;
    for (NSButton*button in self.colorStackView.subviews) {
        if (![button isKindOfClass:NSButton.class]) continue;
        [button.layer setBorderWidth:0.0f];
        if ([button isEqual:currColorButton]) {
            selected = i;
        }
        ++i;
    }
    [self.monster setColorIndex:selected];
    self.botViewLayerOne.layer.backgroundColor = [MonsterPartsFactory colorForIndex:selected].CGColor;
    currColorButton.state = NSControlStateValueOn;
    [currColorButton.layer setBorderWidth:kBorderWidth];
}

- (IBAction)cmdFinishedClick:(id)sender {
    if (self.monsterNameTextField.stringValue.length == 0)
        self.monsterNameTextField.stringValue = @"Bingles Jingleheimer";
    self.monster.monsterName = self.monsterNameTextField.stringValue;
    [NSApplication.sharedApplication sendAction:@selector(viewMonster:) to:nil from:self];
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    if ([collectionView isEqual:self.botViewLayerTwo]) {
        return [MonsterPartsFactory sizeOfBodyArray];
    } else {
        return [MonsterPartsFactory sizeOfFaceArray];
    }
}

- (CGSize)collectionView:(NSCollectionView *)collectionView
                  layout:(NSCollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect bounds = NSInsetRect(self.botViewLayerOne.bounds, -4.0, -4.0);
    return bounds.size;
}

- (NSCollectionViewItem*)collectionView:(NSCollectionView*)collectionView
    itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell =
        (id) [collectionView makeItemWithIdentifier:@"cell" forIndexPath:indexPath];
    if ([collectionView isEqual:self.botViewLayerTwo]) {
        NSImage *bodyImage = [MonsterPartsFactory imageForBody:indexPath.item];
        [cell.imageView setImage:bodyImage];
    } else {
        NSImage *faceImage = [MonsterPartsFactory imageForFace:indexPath.item];
        [cell.imageView setImage:faceImage];
    }
    return cell;
}

- (IBAction)openTestBedScheme:(id)sender {
    NSURL*URL = [NSURL URLWithString:@"testbed-mac://testbed-mac.app.link/KUfCVJ7LnP"];
    NSError*error = nil;
    [[NSWorkspace sharedWorkspace] openURL:URL options:0 configuration:@{} error:&error];
    if (!error) return;
    NSAlert*alert = [NSAlert alertWithError:error];
    [alert runModal];
}

- (IBAction)openTestBedUniversal:(id)sender {
    NSURL*URL = [NSURL URLWithString:@"https://testbed-mac.app.link/KUfCVJ7LnP"];
    NSError*error = nil;
    [[NSWorkspace sharedWorkspace] openURL:URL options:0 configuration:@{} error:&error];
    if (!error) return;
    NSAlert*alert = [NSAlert alertWithError:error];
    [alert runModal];
}

@end
