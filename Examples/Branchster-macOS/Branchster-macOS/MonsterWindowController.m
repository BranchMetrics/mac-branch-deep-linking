//
//  MonsterWindowController.m
//  Branchster-macOS
//
//  Created by Edward on 8/16/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "MonsterWindowController.h"
#import "SplashViewController.h"
#import "MonsterCreatorViewController.h"
#import "MonsterViewerViewController.h"
#import "BranchUniversalObject+MonsterHelpers.h"

static CGRect kFrameRect = { 0.0, 0.0, 600.0, 800.0 };

@interface MonsterWindowController () <NSPageControllerDelegate>
@property (nonatomic, strong) NSPageController*pageController;
@property (nonatomic, strong) MonsterWindowController*myself;
@end;

@implementation MonsterWindowController

+ (MonsterWindowController*) newWindowWithMonster:(BranchUniversalObject*)monster {
    MonsterWindowController*controller =
        [[NSStoryboard storyboardWithName:@"MonsterWindowController" bundle:nil] instantiateInitialController];
    controller.monster = monster;
    [controller.window makeKeyAndOrderFront:self];
    return controller;
}

- (void) awakeFromNib {
    [super awakeFromNib];

    self.myself = self;
    self.shouldCascadeWindows = YES;
    self.window.collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace;

    self.window.backgroundColor = [NSColor whiteColor];
    CGRect r = self.window.frame;
    r.size = kFrameRect.size;
    [self.window setFrame:r display:YES];

    self.pageController = (id) self.contentViewController;
    self.pageController.delegate = self;
    self.pageController.view.frame = kFrameRect;
    self.pageController.arrangedObjects = @[
        [SplashViewController new]
    ];
}

- (void) setMonster:(BranchUniversalObject *)monster {
    _monster = monster;
    if (!_monster) return;

    if (self.pageController.arrangedObjects.count != 2) {
        self.pageController.arrangedObjects = @[
            [MonsterCreatorViewController new],
            [MonsterViewerViewController new]
        ];
    }
    for (NSViewController*controller in self.pageController.arrangedObjects) {
        if ([controller respondsToSelector:@selector(setMonster:)])
            [(id)controller setMonster:self.monster];
    }
    [self.window makeKeyAndOrderFront:nil];
}

- (NSPageControllerObjectIdentifier)pageController:(NSPageController *)pageController
                               identifierForObject:(id<NSObject>)object {
    return NSStringFromClass(object.class);
}

- (NSViewController *)pageController:(NSPageController *)pageController
         viewControllerForIdentifier:(NSPageControllerObjectIdentifier)identifier {
    NSViewController*controller = nil;
    for (NSViewController*vc in self.pageController.arrangedObjects) {
        if ([vc isKindOfClass:NSClassFromString(identifier)]) {
            controller = vc;
            break;
        }
    }

    // Set debug frame colors:
    self.window.contentView.layer.borderColor = [NSColor greenColor].CGColor;
    self.window.contentView.layer.borderWidth = 2.0;
    self.pageController.view.layer.borderColor = [NSColor redColor].CGColor;
    self.pageController.view.layer.borderWidth = 4.0;
    controller.view.layer.borderColor = [NSColor blueColor].CGColor;
    controller.view.layer.borderWidth = 1.0f;

    controller.view.frame = kFrameRect;
    return controller;
}

- (void) close {
    [super close];
    self.myself = nil;
}

- (IBAction) viewMonster:(id)sender {
    self.pageController.selectedIndex = 1;
}

- (IBAction) editMonster:(id)sender {
    self.pageController.selectedIndex = 0;
}

@end
