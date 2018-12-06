//
//  APPTextView.m
//  TestBed-tvOS
//
//  Created by Edward on 8/2/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPTextView.h"

@interface APPTextView () {
    UILabel*_placeholderLabel;
}
@end

@implementation APPTextView

UIColor*kNormalBackgroundColor = nil;
UIColor*kSelectedBackgroundColor = nil;

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return self;

    if (!kNormalBackgroundColor) {
        kNormalBackgroundColor = [UIColor colorWithWhite:1.0 alpha:0.80];
        kSelectedBackgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }

    self.selectable = YES;
    self.userInteractionEnabled = YES;
    self.scrollEnabled = NO;
    self.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    self.backgroundColor = kNormalBackgroundColor;

    return self;
}

- (UILabel*) placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 15.0, 0.0, 0.0)];
        _placeholderLabel.textColor = [UIColor lightGrayColor];
        [self addSubview:_placeholderLabel];
    }
    return _placeholderLabel;
}

- (void) setText:(NSString *)text {
    [super setText:text];
    if (text.length) {
        _placeholderLabel.hidden = YES;
    } else {
        [_placeholderLabel sizeToFit];
        _placeholderLabel.hidden = NO;
    }
}

- (BOOL) canBecomeFocused {
    return YES;
}

- (void) didUpdateFocusInContext:(UIFocusUpdateContext *)context
        withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {

    if (context.nextFocusedView == self) {
        [coordinator addCoordinatedFocusingAnimations:^(id<UIFocusAnimationContext>  _Nonnull animationContext) {
            self.transform = CGAffineTransformMakeScale(1.02, 1.02);
            self.backgroundColor = kSelectedBackgroundColor;
            self.layer.shadowRadius = 10.0;
            self.layer.shadowOpacity = 0.35;
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOffset = CGSizeMake(0.0, 20.0);
            self.clipsToBounds = NO;
        }
        completion:nil];
    } else
    if (context.previouslyFocusedItem == self) {
        [coordinator addCoordinatedUnfocusingAnimations:^(id<UIFocusAnimationContext>  _Nonnull animationContext) {
            self.transform = CGAffineTransformIdentity;
            self.backgroundColor = kNormalBackgroundColor;
            self.layer.shadowColor = nil;
        }
        completion:nil];
    }
}

- (void) pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    [super pressesBegan:presses withEvent:event];
    UIPress*press = [presses anyObject];
    if (press.type == UIPressTypeSelect) {
        self.selected = !self.selected;
        if ([self.delegate respondsToSelector:@selector(textViewWasSelected:)])
            [((id<APPTextViewDelegate>)self.delegate) textViewWasSelected:self];
    }
}

@end
