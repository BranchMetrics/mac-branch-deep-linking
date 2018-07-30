//
//  TBToggleButton.h
//  TestBed-tvOS
//
//  Created by Edward on 7/30/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TBToggleButton : UIButton
+ (instancetype) toggleButton;
@property (nonatomic, assign) BOOL on;
@property (nonatomic, strong) UIColor*onTintColor;
@property (nonatomic, strong) UIColor*offTintColor;
@end
