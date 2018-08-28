//
//  MonsterWindowController.m
//  Branchster-macOS
//
//  Created by Edward Smith on 8/16/18.
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
    self.window.collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace;
    self.window.backgroundColor = [NSColor whiteColor];

    static CGRect lastWindowRect = { 0.0, 0.0, 0.0, 0.0 };
    static NSPoint lastTopLeft;
    if (CGRectEqualToRect(lastWindowRect, NSZeroRect)) {
        lastWindowRect.origin = self.window.frame.origin;
        lastWindowRect.size = kFrameRect.size;
        lastTopLeft.x = lastWindowRect.origin.x;
        lastTopLeft.y = lastWindowRect.origin.y + lastWindowRect.size.height;
    }
    [self.window setFrame:lastWindowRect display:YES];
    lastTopLeft = [self.window cascadeTopLeftFromPoint:lastTopLeft];

    self.pageController = (id) self.contentViewController;
    self.pageController.delegate = self;
    self.pageController.view.frame = kFrameRect;
    self.pageController.arrangedObjects = @[
        [SplashViewController new]
    ];
}

- (void) setMonster:(BranchUniversalObject *)monster {
    if (_monster) [_monster removeObserver:self forKeyPath:@"monsterName"];
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
    if (_monster) [_monster addObserver:self forKeyPath:@"monsterName" options:0 context:0];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
        ofObject:(id)object
        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
        context:(void *)context {
    NSString*title = self.monster.monsterName;
    if (title.length <= 0) title = @"Branch Monster Factory";
    self.window.title = title;
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
    if (!controller) controller = self.pageController.arrangedObjects.firstObject;
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
