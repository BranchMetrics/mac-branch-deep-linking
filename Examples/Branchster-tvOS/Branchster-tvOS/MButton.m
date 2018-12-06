//
//  MButton.m
//  Branchster-tvOS
//
//  Created by Edward Smith on 9/5/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "MButton.h"

UIImage* MImageWithColorSize(UIColor*color, CGSize size) {
    CGRect r = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    [color setFill];
    UIRectFill(r);
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@implementation MButton

/*
- (void) didUpdateFocusInContext:(UIFocusUpdateContext *)context
      withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        if (self.focused)
            self.backgroundColor = [UIColor whiteColor];
        else
            self.backgroundColor = [UIColor clearColor];
        }
        completion:nil];
}
*/

- (void) setBackgroundColor:(UIColor *)backgroundColor {
    UIImage*image = nil;
    if (backgroundColor != nil) image = MImageWithColorSize(backgroundColor, self.bounds.size);
    [self setBackgroundImage:image forState:UIControlStateNormal];
    [super setBackgroundColor:[UIColor whiteColor]];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

@end
