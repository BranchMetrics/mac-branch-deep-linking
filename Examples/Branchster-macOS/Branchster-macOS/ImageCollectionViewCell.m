//
//  ImageCollectionViewCell.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/7/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

#import "ImageCollectionViewCell.h"

@implementation ImageCollectionViewCell

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    return self;
}

/*
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self && !self.imageView) {
        self.imageView = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:self.imageView];
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
*/

@end
