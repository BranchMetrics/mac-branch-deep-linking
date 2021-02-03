//
//  AppDelegate.h
//  TestDeepLinking
//
//  Created by Nidhi on 2/3/21.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField *notification;
@property (weak) IBOutlet NSScrollView *logs;
@property (unsafe_unretained) IBOutlet NSTextView *sessionData;

- (void) processLogMessage:(NSString*)message;

@end

