//
//  TBToggleButton.m
//  TestBed-tvOS
//
//  Created by Edward on 7/30/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "TBToggleButton.h"

@implementation TBToggleButton

+ (instancetype) toggleButton {
    TBToggleButton*toggle = [[TBToggleButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
    [toggle setTitle:@"Off" forState:UIControlStateNormal];
    [toggle setTitle:@"On"  forState:UIControlStateSelected];
    toggle.onTintColor = [UIColor greenColor];
    toggle.offTintColor = [UIColor grayColor];
    toggle.layer.borderColor = toggle.offTintColor.CGColor;
    toggle.layer.borderWidth = 0.5;
    toggle.layer.cornerRadius = 2.0;
    return toggle;
}

- (BOOL) on {
    return self.isSelected;
}

- (void) setOn:(BOOL)on {
    self.selected = YES;
}

- (void) setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderColor = (selected)
        ? self.onTintColor.CGColor
        : self.offTintColor.CGColor;
}

@end
