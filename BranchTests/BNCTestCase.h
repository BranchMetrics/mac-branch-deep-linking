/**
 @file          BNCTestCase.h
 @package       BranchTests
 @brief         The Branch testing framework super class.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "NSString+Branch.h"
#import "BNCThreads.h"
#import "BranchMainClass+Private.h"
#import "BNCTestNetworkService.h"
#import "BNCDevice.h"

FOUNDATION_EXPORT NSString*_Nonnull const BNCTestBranchKey;

#define BNCTAssertEqualMaskedString(string, mask) { \
    if ((id)string != nil && (id)mask != nil && [string bnc_isEqualToMaskedString:mask]) { \
    } else { \
        XCTAssertEqualObjects(string, mask); \
    } \
}

NS_ASSUME_NONNULL_BEGIN

extern BOOL BNCTestStringMatchesRegex(NSString *string, NSString *regex);

#define XCTAssertStringMatchesRegex(string, regex) \
    XCTAssertTrue(BNCTestStringMatchesRegex(string, regex))

@interface BNCTestCase : XCTestCase

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation;
- (void)awaitExpectations;
- (void)resetExpectations;
//- (id)stringMatchingPattern:(NSString *)pattern;

// Load Resources from the test bundle:

- (NSString*_Nullable)stringFromBundleWithKey:(NSString*)key;
- (NSString*_Nullable)stringFromBundleJSONWithKey:(NSString *)key;
- (NSMutableDictionary*_Nullable)mutableDictionaryFromBundleJSONWithKey:(NSString*)key;

+ (BOOL) breakpointsAreEnabledInTests;
@end

NS_ASSUME_NONNULL_END
