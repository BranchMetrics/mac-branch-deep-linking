//
//  BranchQRCode.h
//  BranchMacOS
//
//  Created by Nipun Singh on 5/23/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"
#import "BranchHeader.h"

#ifndef BranchQRCode_h
#define BranchQRCode_h

typedef NS_ENUM(NSInteger, BranchQRCodeImageFormat){
    BranchQRCodeImageFormatPNG,
    BranchQRCodeImageFormatJPEG
};

@interface BranchQRCode : NSObject

/// Primary color of the generated QR code itself.
@property (nonatomic, copy, readwrite) NSColor * _Nullable codeColor;
/// Secondary color used as the QR Code background.
@property (nonatomic, copy, readwrite) NSColor * _Nullable backgroundColor;
/// A URL of an image that will be added to the center of the QR code. Must be a PNG or JPEG.
@property (nonatomic, copy, readwrite) NSString * _Nullable centerLogo;
/// Output size of QR Code image. Min 500px. Max 2000px.
@property (nonatomic, readwrite) NSNumber * _Nullable width;
/// The number of pixels for the QR code's border.  Min 0px. Max 20px.
@property (nonatomic, readwrite) NSNumber * _Nullable margin;
/// Format of the returned QR code. Can be a JPEG or PNG.
@property (nonatomic, assign, readwrite) BranchQRCodeImageFormat imageFormat;

/**
Creates a Branch QR Code image. Returns the QR code as a CIImage.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing the QR code image and error.

*/
- (void) getQRCodeAsImage:(BranchUniversalObject*_Nullable)buo
    linkProperties:(BranchLinkProperties*_Nullable)lp
               completion:(void(^_Nonnull)(CIImage * _Nullable qrCode, NSError * _Nullable error))completion;

/**
Creates a Branch QR Code image. Returns the QR code as NSData.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing the QR code image and error.

*/
- (void) getQRCodeAsData:(BranchUniversalObject*_Nullable)buo
    linkProperties:(BranchLinkProperties*_Nullable)lp
              completion:(void(^_Nonnull)(NSData * _Nullable qrCode, NSError * _Nullable error))completion;


@end


#endif /* BranchQRCode_h */
