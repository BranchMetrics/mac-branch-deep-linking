//
//  TestBedUITest.h
//  TestBed-macOS
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#ifndef TestBedUITest_h
#define TestBedUITest_h

#import <XCTest/XCTest.h>

#define TRACKING_STATE_UNKNOWN      -1
#define TRACKING_ENABLED            0
#define TRACKING_DISABLED           1

@interface TestBedUITest : XCTestCase

@property BOOL appLaunched;
@property NSInteger trackingState;

- (XCTWaiterResult) launchAppAndWaitForSessionStart;
- (NSString *) serverRequestString;
- (NSString *) serverResponseString;
- (void) setIdentity;
- (void) logOut;
- (NSString *) createShortLink;
- (void) openLastLink;
- (NSString *) getErrorString;
- (void) logEvent:(NSString *)eventName;
- (void) logAllEvents;
- (NSString *) dataTextViewString;
-(void) enableTracking;
-(void) disableTracking;
-(void) terminateTestBed;
-(NSString *) webPageURLWithRedirection:(BOOL)enabled;
- (void) validateDeepLinkDataForRedirectionEnabled:(bool)enabled;

@end


#endif /* TestBedUITest_h */

// Adding this message for testing integration on commit from remote machine.
