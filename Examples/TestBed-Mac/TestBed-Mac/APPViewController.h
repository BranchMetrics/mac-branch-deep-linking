//
//  APPViewController.h
//  TestBed-Mac
//
//  Created by Edward Smith on 5/15/18.
//  Copyright © 2018 Edward Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APPViewController : NSViewController
+ (APPViewController*) loadController;
@property (weak)   IBOutlet NSTextField *stateField;
@property (weak)   IBOutlet NSTextField *urlField;
@property (weak)   IBOutlet NSTextField *errorField;
@property (strong) IBOutlet NSTextView *dataTextView;
@property (nonatomic, strong) IBOutlet NSWindow* window;
@end
