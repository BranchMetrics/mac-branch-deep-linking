//
//  APPTextView.h
//  TestBed-tvOS
//
//  Created by Edward on 8/2/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>
@class APPTextView;

@protocol APPTextViewDelegate
@optional
- (void) textViewWasSelected:(APPTextView*)textView;
@end

@interface APPTextView : UITextView
@property (nonatomic, strong) UILabel*placeholderLabel;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@end
