//
//  TestBed-macOSTests.m
//  TestBed-macOSTests
//
//  Created by Edward Smith on 5/21/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface TestBedmacOSTests : XCTestCase
@end

@implementation TestBedmacOSTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSLog(@"Yo");
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
