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

@interface TestBedUITest : XCTestCase

@property BOOL appLaunched;

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
- (void) terminateApp;
- (NSString *) dataTextViewString;
-(BOOL) trackingDisabled;
-(void) enableTracking;
-(void) disableTracking;
-(void) terminateTestBed;
-(void) terminateSafari;

@end


#endif /* TestBedUITest_h */
