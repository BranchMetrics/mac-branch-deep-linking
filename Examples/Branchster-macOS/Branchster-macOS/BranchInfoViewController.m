//
//  BranchInfoViewController.m
//  BranchMonsterFactory
//
//  Created by Sahil Verma on 5/18/15.
//  Copyright (c) 2015 Branch. All rights reserved.
//

#import "BranchInfoViewController.h"
@import Branch;

@interface BranchInfoViewController ()
@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;
@end

@implementation BranchInfoViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.versionLabel.stringValue =
        [NSString stringWithFormat:@"%@ / %@",
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            Branch.kitDisplayVersion];
}

-(IBAction) openWebAction:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"https://branch.io"];
    NSError*error = nil;
    [[NSWorkspace sharedWorkspace] openURL:URL options:0 configuration:@{} error:&error];
    if (!error) return;
    NSAlert*alert = [NSAlert alertWithError:error];
    [alert runModal];
}

@end
