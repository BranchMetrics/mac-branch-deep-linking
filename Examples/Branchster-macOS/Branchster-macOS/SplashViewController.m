//
//  SplashViewController.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()
@property (nonatomic, weak) IBOutlet NSTextField *txtNote;
@property (nonatomic, strong) NSArray *loadingMessages;
@property (nonatomic, assign) NSInteger messageIndex;
@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loadingMessages = @[
        @"Loading Branchster parts",
        @"Loading Branchster parts.",
        @"Loading Branchster parts..",
        @"Loading Branchster parts..."
    ];
    
    [NSTimer scheduledTimerWithTimeInterval:0.3
        target:self
        selector:@selector(updateMessageIndex)
        userInfo:nil
        repeats:YES];
}

- (void) updateMessageIndex {
    self.messageIndex = (self.messageIndex + 1)%[self.loadingMessages count];
    self.txtNote.stringValue = self.loadingMessages[self.messageIndex];
}

@end
