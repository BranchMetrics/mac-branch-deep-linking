//
//  TestBed_macOSUITests.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 10/16/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface TestBed_macOSUITests : XCTestCase

@end

@implementation TestBed_macOSUITests

- (void)setUp {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSendV2Events {
    
    XCUIElement *testbedMacWindow = [[XCUIApplication alloc] init].windows[@"TestBed-Mac"];
    XCUIElement *sendV2EventStaticText = testbedMacWindow.collectionViews.staticTexts[@"Send Event"];
    XCUIElementQuery *sheetsQuery = testbedMacWindow.sheets;
    XCUIElement *button = [sheetsQuery.comboBoxes[@"Select V2 Event"] childrenMatchingType:XCUIElementTypeButton].element;
    XCUIElementQuery *elementsQuery = sheetsQuery.scrollViews.otherElements;
    XCUIElement *sendButton = sheetsQuery.buttons[@"Send"];

    int numberOfElementsLeft = 0;
    int counter = 0 ;
    do{
       
        [sendV2EventStaticText click];
        [button click];
        numberOfElementsLeft = (int)[[[elementsQuery childrenMatchingType:XCUIElementTypeTextField] allElementsBoundByIndex] count];
        [[[elementsQuery childrenMatchingType:XCUIElementTypeTextField] elementBoundByIndex:counter] click];
        counter += 1;
        numberOfElementsLeft = numberOfElementsLeft - counter;
        [sendButton click];
    } while (numberOfElementsLeft > 0) ;
}

@end
