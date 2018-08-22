//
//  BranchUniversalObject+MonsterHelpers.h
//  BranchMonsterFactory
//
//  Created by Dan Walkowski on 12/4/15.
//  Copyright © 2015 Branch. All rights reserved.
//

@import Foundation;
@import Branch;

@interface BranchUniversalObject (MonsterHelpers)

+ (BranchUniversalObject *)emptyMonster;

@property (nonatomic, assign) BOOL isMonster;
@property (nonatomic, strong) NSString *monsterName;
@property (nonatomic, assign) NSInteger faceIndex;
@property (nonatomic, assign) NSInteger bodyIndex;
@property (nonatomic, assign) NSInteger colorIndex;
@property (nonatomic, strong, readonly) NSString *monsterDescription;
@end
