/**
 @file          BNCTestCase.m
 @package       BranchTests
 @brief         The Branch testing framework super class.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCLog.h"
#import "BNCSettings.h"

// File is 'BNCTestCase.strings'. Omit the '.string'.
NSString*_Nonnull const     BNCTestStringResourceName = @"BNCTestCase";
NSString*_Nonnull const     BNCTestBranchKey    = @"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N";
//NSString*_Nonnull const     BNCTestBranchKey    = @"key_live_ait5BYsDbZKRajyPlkzzTancDAp41guC";

#pragma mark - BNCTestStringMatchesRegex

BOOL BNCTestStringMatchesRegex(NSString *string, NSString *regex) {
    NSError *error = nil;
    NSRegularExpression* nsregex =
        [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
    if (error) {
        NSLog(@"Error in regex pattern: %@.", error);
        return NO;
    }
    NSRange stringRange = NSMakeRange(0, string.length);
    NSTextCheckingResult *match = [nsregex firstMatchInString:string options:0 range:stringRange];
    return NSEqualRanges(match.range, stringRange);
}

#pragma mark - BNCTestCase

@interface BNCTestCase ()
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end

@implementation BNCTestCase

+ (void) setUp {
    BNCTestNetworkService.requestHandler = nil;
    [[[BNCSettings alloc] init] clearAllSettings];
}

- (void)setUp {
    [super setUp];
    [self resetExpectations];
}

- (void)resetExpectations {
    self.hasExceededExpectations = NO;
}

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        self.hasExceededExpectations = YES;
    }];
}

/*
- (id)stringMatchingPattern:(NSString *)pattern {
    NSRegularExpression *regex =
        [[NSRegularExpression alloc]
            initWithPattern:pattern
            options:NSRegularExpressionCaseInsensitive
            error:nil];

    return [OCMArg checkWithBlock:^BOOL(NSString *param) {
        return [regex numberOfMatchesInString:param
            options:kNilOptions range:NSMakeRange(0, param.length)] > 0;
    }];
}
*/

- (NSString*) stringFromBundleWithKey:(NSString*)key {
    NSString *const kItemNotFound = @"<Item-Not-Found>";
    NSString *resource =
        [[NSBundle bundleForClass:self.class]
            localizedStringForKey:key value:kItemNotFound table:BNCTestStringResourceName];
    if ([resource isEqualToString:kItemNotFound]) resource = nil;
    return resource;
}

- (NSMutableDictionary*) mutableDictionaryFromBundleJSONWithKey:(NSString*)key {
    NSError*error = nil;
    NSBundle*bundle = [NSBundle bundleForClass:self.class];
    NSURL*url = [bundle URLForResource:@"BNCTestCase" withExtension:@"json"];
    NSData*data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    XCTAssert(error == nil && data != nil, @"Can't bundle test JSON!");
    if (error || !data) return nil;

    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssert(error == nil && dictionary);
    if (!dictionary) return nil;
    NSDictionary *result = dictionary[key];
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:result];
    return mutableDictionary;
}

- (NSString*)stringFromBundleJSONWithKey:(NSString *)key {
    NSMutableDictionary*dictionary = [self mutableDictionaryFromBundleJSONWithKey:key];
    if (!dictionary) return nil;
    NSError*error = nil;
    NSData*data = [NSJSONSerialization dataWithJSONObject:dictionary options:3 error:&error];
    XCTAssertNil(error);
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static BOOL _breakpointsAreEnabledInTests = NO;

+ (BOOL) breakpointsAreEnabledInTests {
    return _breakpointsAreEnabledInTests;
}

+ (void) initialize {
    if (self != [BNCTestCase self]) return;
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    // Load test options from environment variables:

    NSDictionary<NSString*, NSString*> *environment = [NSProcessInfo processInfo].environment;
    NSString *BNCTestBreakpoints = environment[@"BNCTestBreakpointsEnabled"];
    if ([BNCTestBreakpoints boolValue]) {
        _breakpointsAreEnabledInTests = YES;
    }
}

@end
