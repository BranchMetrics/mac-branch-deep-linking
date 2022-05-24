//
/**
 @file          BranchQRCodeTest.m
 @package       BranchTests
 @brief         Tests the QR code generation methods.

 @author        Nipun Singh
 @date          2022
 @copyright     Copyright © 2022 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCQRCodeCache.h"

@interface BranchQRCodeTest : XCTestCase

@end

@implementation BranchQRCodeTest

- (void)testNormalQRCodeDataWithAllSettings {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.width = @(1000);
    qrCode.margin = @(1);
    qrCode.codeColor = NSColor.blueColor;
    qrCode.backgroundColor = NSColor.whiteColor;
    qrCode.centerLogo = @"https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg";
    qrCode.imageFormat = BranchQRCodeImageFormatPNG;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeAsDataWithNoSettings {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeWithInvalidLogoURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.centerLogo = @"https://branch.branch/notARealImageURL.jpg";
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeAsImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsImage:buo linkProperties:lp completion:^(CIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testQRCodeCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];
    
    BranchQRCode *myQRCode = [BranchQRCode new];
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [myQRCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        NSMutableDictionary *settings = [NSMutableDictionary new];
        
        settings[@"image_format"] = @"PNG";
        
        parameters[@"qr_code_settings"] = settings;
        parameters[@"data"] = [NSMutableDictionary new];
        parameters[@"branch_key"] = [[Branch sharedInstance] getKey];
        
        NSData *cachedQRCode = [[BNCQRCodeCache sharedInstance] checkQRCodeCache:parameters];
       
        XCTAssertEqual(cachedQRCode, qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

@end
