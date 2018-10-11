//
//  BranchUniversalObject+MonsterHelpers.m
//  BranchMonsterFactory
//
//  Created by Dan Walkowski on 12/4/15.
//  Copyright © 2015 Branch. All rights reserved.
//

#import "BranchUniversalObject+MonsterHelpers.h"
#import "MonsterPartsFactory.h"

@implementation BranchUniversalObject (MonsterHelpers)

- (void)setIsMonster:(BOOL)value {
    self.contentMetadata.customMetadata[@"monster"] = (value) ? @"true" : @"false";
}

- (BOOL) isMonster {
    return [self.contentMetadata.customMetadata[@"monster"] boolValue];
}

- (void)setMonsterName:(NSString *)name {
    self.contentMetadata.customMetadata[@"monster_name"] = name;
}

- (NSString *) monsterName {
    return self.contentMetadata.customMetadata[@"monster_name"];
}

- (void)setFaceIndex:(NSInteger)index {
    self.contentMetadata.customMetadata[@"face_index"] = [@(index) stringValue];
}

- (NSInteger)faceIndex {
    return [self.contentMetadata.customMetadata[@"face_index"] integerValue];
}

- (void)setBodyIndex:(NSInteger)index {
    self.contentMetadata.customMetadata[@"body_index"] = [@(index) stringValue];
}

- (NSInteger) bodyIndex {
    return [self.contentMetadata.customMetadata[@"body_index"] integerValue];
}

- (void)setColorIndex:(NSInteger)index {
    self.contentMetadata.customMetadata[@"color_index"] = [@(index) stringValue];
}

- (NSInteger)colorIndex {
    return [self.contentMetadata.customMetadata[@"color_index"] integerValue];
}

- (NSString *) monsterDescription {
    return [NSString stringWithFormat:
        [MonsterPartsFactory descriptionForIndex:self.faceIndex],
        [self monsterName]];
}

+ (BranchUniversalObject *)emptyMonster {
    BranchUniversalObject *empty =
        [[BranchUniversalObject alloc] initWithTitle:@"Jingles Bingleheimer"];
    [empty setIsMonster:YES];
    [empty setFaceIndex:0];
    [empty setBodyIndex:0];
    [empty setColorIndex:0];
    [empty setMonsterName:@""];
    return empty;
}

@end
