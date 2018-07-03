/**
 @file          BNCEncoder.Test.m
 @package       BranchTests
 @brief         Tests for BNCEncoder.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCEncoder.h"

#pragma mark TestClass

@interface TestClass : NSObject <NSSecureCoding>
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

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    [BNCEncoder decodeInstance:self withCoder:aDecoder ignoring:nil];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:nil];
}

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
       fabs(self.f - other.f) < 0.0001 &&
       fabs(self.d - other.d) < 0.0001) {
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

#pragma mark - BNCEncoderTest

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
    [encoder finishEncoding];
    XCTAssert(error == nil && data.length > 0);

    TestClass*v = [[TestClass alloc] init];
    NSKeyedUnarchiver*decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    error = [BNCEncoder decodeInstance:v withCoder:decoder ignoring:nil];
    XCTAssert(error == nil);
    XCTAssertTrue([t isEqual:v]);
}

- (void) testEncode2 {
    TestClass*t = [TestClass createTestInstance];
    t.b1 = YES;
    t.b2 = YES;
    t.i1 = 0;
    NSMutableData*data = [NSMutableData new];
    NSKeyedArchiver*encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSError*error = [BNCEncoder encodeInstance:t withCoder:encoder ignoring:nil];
    [encoder finishEncoding];
    XCTAssert(error == nil && data.length > 0);

    TestClass*v = [[TestClass alloc] init];
    NSKeyedUnarchiver*decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    error = [BNCEncoder decodeInstance:v withCoder:decoder ignoring:nil];
    XCTAssert(error == nil);
    XCTAssertTrue([t isEqual:v]);
}

- (void) testEncodeIgnore1 {
    TestClass*t = [TestClass createTestInstance];
    NSMutableData*data = [NSMutableData new];
    NSKeyedArchiver*encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSError*error = [BNCEncoder encodeInstance:t withCoder:encoder ignoring:@[@"_ignored"]];
    [encoder finishEncoding];
    XCTAssert(error == nil && data.length > 0);

    TestClass*v = [[TestClass alloc] init];
    NSKeyedUnarchiver*decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    error = [BNCEncoder decodeInstance:v withCoder:decoder ignoring:nil];
    XCTAssert(error == nil);

    t.ignored = nil;
    XCTAssertTrue([t isEqual:v]);
}

- (void) testEncodeIgnore2 {
    TestClass*t = [TestClass createTestInstance];
    NSMutableData*data = [NSMutableData new];
    NSKeyedArchiver*encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSError*error = [BNCEncoder encodeInstance:t withCoder:encoder ignoring:nil];
    [encoder finishEncoding];
    XCTAssert(error == nil && data.length > 0);

    TestClass*v = [[TestClass alloc] init];
    NSKeyedUnarchiver*decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    error = [BNCEncoder decodeInstance:v withCoder:decoder ignoring:@[@"_ignored"]];
    XCTAssert(error == nil);

    t.ignored = nil;
    XCTAssertTrue([t isEqual:v]);
}

- (void) testNSKeyedArchiver {
    TestClass*t = [TestClass createTestInstance];
    NSData*data = [NSKeyedArchiver archivedDataWithRootObject:t];
    TestClass*v = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertTrue([t isEqual:v]);
}

@end
