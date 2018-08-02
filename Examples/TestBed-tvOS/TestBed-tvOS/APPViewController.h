//
//  APPViewController.h
//  TestBed-tvOS
//
//  Created by Edward Smith on 8/1/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APPTextView.h"

@interface APPViewController : UIViewController
- (void) clearUIFields;
@property (weak)   IBOutlet UILabel *stateField;
@property (weak)   IBOutlet UILabel *urlField;
@property (weak)   IBOutlet UILabel *errorField;
@property (weak)   IBOutlet UIStackView *stackView;
@property (strong) IBOutlet APPTextView *dataTextView;
@property (strong) IBOutlet APPTextView *requestTextView;
@property (strong) IBOutlet APPTextView *responseTextView;
@end
