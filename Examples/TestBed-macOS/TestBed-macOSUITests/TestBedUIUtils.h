//
//  TestBedUIUtils.h
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define TESTBED_CLICK_LINK     "https://testbed-mac.app.link/ODYeswaVWM"

@interface TestBedUIUtils : NSObject

+ (NSDictionary *) dictionaryFromString:(NSString *)APIDataString;
+ (void) deleteSettingsFiles;

@end

NS_ASSUME_NONNULL_END
