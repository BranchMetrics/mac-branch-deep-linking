//
//  MonsterWindowController.h
//  Branchster-macOS
//
//  Created by Edward Smith on 8/16/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BranchUniversalObject;

@interface MonsterWindowController : NSWindowController
+ (MonsterWindowController*) newWindowWithMonster:(BranchUniversalObject*)monster;
- (IBAction) viewMonster:(id)sender;
- (IBAction) editMonster:(id)sender;
@property (nonatomic, strong) BranchUniversalObject*monster;
@end;
