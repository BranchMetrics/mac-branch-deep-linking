//
//  MonsterWindowController.h
//  Branchster-macOS
//
//  Created by Edward on 8/16/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BranchUniversalObject;

@interface MonsterWindowController : NSWindowController
+ (MonsterWindowController*) newWindowWithMonster:(BranchUniversalObject*)monster;
@property (nonatomic, strong) BranchUniversalObject*monster;

- (IBAction) viewMonster:(id)sender;
- (IBAction) editMonster:(id)sender;
@end;
