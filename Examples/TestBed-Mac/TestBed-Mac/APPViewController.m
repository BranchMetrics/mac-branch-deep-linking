//
//  APPViewController.m
//  TestBed-Mac
//
//  Created by Edward Smith on 5/15/18.
//  Copyright © 2018 Edward Smith. All rights reserved.
//

#import "APPViewController.h"

@interface APPViewController ()
@property (strong) IBOutlet NSTextField *urlField;
@property (strong) IBOutlet NSTextField *deepLinkDataField;
@end

@implementation APPViewController

+ (APPViewController*) loadController {
    APPViewController*controller = [[APPViewController alloc] init];
    BOOL loaded =
        [[NSBundle mainBundle]
            loadNibNamed:NSStringFromClass(self)
            owner:controller
            topLevelObjects:nil];
    return (loaded) ? controller : nil;
}

- (void) awakeFromNib {
}

- (void) dealloc {
}

@end
