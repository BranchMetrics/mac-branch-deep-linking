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
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@end

@implementation BranchInfoViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.versionLabel.text =
        [NSString stringWithFormat:@"%@ / %@",
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            Branch.kitDisplayVersion];
}

-(IBAction) openWebAction:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"https://branch.io"];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^ (BOOL success) {
        if (success) return;
        UIAlertController* alert =
            [UIAlertController alertControllerWithTitle:@"Open Failed"
                message:[NSString stringWithFormat:@"Can't open the URL '%@'.", URL.absoluteString]
                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction*defaultAction =
            [UIAlertAction actionWithTitle:@"OK"
                style:UIAlertActionStyleDefault
                handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
