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
@property (nonatomic, strong) IBOutlet NSWindow* window;
@end
