/**
 @file          BNCEncoder.Test.m
 @package       BranchTests
 @brief         < A brief description of the file function. >

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCEncoder.h"

@interface TestClass : NSObject
@property (strong) NSString*string;
@property (assign) BOOL b1;
@property (assign) NSInteger i1;
@property (assign) BOOL b2;
@property (strong) NSString*ignored;
@property (strong) NSDictionary* dict;
@property (assign) CGFloat f;
@property (assign) double d;
@end

@implementation TestClass

- (BOOL) isEqual:(TestClass*)other {
    if (!!self.string == !!other.string &&
       (self.string == nil || [self.string isEqualToString:other.string]) &&
       !!self.b1 == !!other.b1 &&
       self.i1 == other.i1 &&
       !!self.b2 == !!other.b2 &&
       !!self.ignored == !!other.ignored &&
       (self.ignored == nil || [self.ignored isEqualToString:other.ignored]) &&
       !!self.dict == !!other.dict &&
       (self.dict == nil || [self.dict isEqualToDictionary:other.dict]) &&
       self.f == other.f &&
       self.d == other.d) {
            return YES;
    }
    return NO;
}

+ (instancetype) createTestInstance {
    TestClass*t = [[TestClass alloc] init];
    t.string = @"My string.";
    t.b1 = NO;
    t.i1 = -1;
    t.b2 = NO;
    t.ignored = @"Not me!";
    t.dict = @{
        @"key": @"value"
    };
    t.f = 1.0;
    t.d = -100.100;
    return t;
}

@end

@interface BNCEncoderTest : BNCTestCase
@end

@implementation BNCEncoderTest

- (void) testTestClassEqual {
    TestClass*a = [TestClass createTestInstance];
    TestClass*b = [TestClass createTestInstance];
    XCTAssertTrue([a isEqual:b]);
    XCTAssertEqualObjects(a, b);
}

- (void) testTestClassNotEqual1 {
    TestClass*a = [TestClass createTestInstance];
    TestClass*b = [TestClass createTestInstance];
    a.dict = @{
        @"KeyNew": @"ValueNew"
    };
    XCTAssertFalse([a isEqual:b]);
}

- (void) testTestClassNotEqual2 {
    TestClass*a = [TestClass createTestInstance];
    TestClass*b = [TestClass createTestInstance];
    b.string = @"MOOW";
    XCTAssertFalse([a isEqual:b]);
}

- (void) testEncode1 {
    TestClass*t = [TestClass createTestInstance];
    NSMutableData*data = [NSMutableData new];
    NSKeyedArchiver*encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSError*error = [BNCEncoder encodeInstance:t withCoder:encoder ignoring:nil];
    XCTAssert(error == nil);

    TestClass*v = [[TestClass alloc] init];
    NSKeyedUnarchiver*decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    error = [BNCEncoder decodeInstance:v withCoder:decoder ignoring:nil];
    XCTAssert(error == nil);
    XCTAssertTrue([t isEqual:v]);
}

@end
