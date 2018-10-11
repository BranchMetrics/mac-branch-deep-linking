//
//  MonsterViewerViewController.h
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

@import UIKit;
@import Branch;

@interface MonsterViewerViewController : UIViewController
+ (MonsterViewerViewController*) viewControllerWithMonster:(BranchUniversalObject*)monster;
@property (nonatomic, strong) BranchUniversalObject *monster;
@end

