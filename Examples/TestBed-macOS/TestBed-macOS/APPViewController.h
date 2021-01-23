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
@property (weak)   IBOutlet NSButton *trackingDisabled;
@property (weak)   IBOutlet NSButton *limitFacebookTracking;
@property (weak)   IBOutlet NSTextField *stateField;
@property (weak)   IBOutlet NSTextField *urlField;
@property (weak)   IBOutlet NSTextField *errorField;
@property (strong) IBOutlet NSTextView *dataTextView;
@property (strong) IBOutlet NSTextView *requestTextView;
@property (strong) IBOutlet NSTextView *responseTextView;
@property (nonatomic, strong) IBOutlet NSWindow* window;

- (void) clearUIFields;
- (NSArray *) v2Events;

@end
