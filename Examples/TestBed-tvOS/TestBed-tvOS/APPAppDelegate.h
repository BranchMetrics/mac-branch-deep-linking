//
//  APPAppDelegate.h
//  TestBed-tvOS
//
//  Created by Edward Smith on 8/1/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>
@class APPViewController;

@interface APPAppDelegate : UIResponder <UIApplicationDelegate>
- (void) processLogMessage:(NSString*)message;
@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet APPViewController*viewController;
@end
