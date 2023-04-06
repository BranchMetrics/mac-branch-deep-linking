//
//  BranchQRCode.m
//  BranchMacOS
//
//  Created by Nipun Singh on 5/23/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <LinkPresentation/LPLinkMetadata.h>
#import "BranchQRCode.h"
#import "Branch.h"
#import "BNCQRCodeCache.h"

@implementation BranchQRCode

NSString *buoTitle;
CIImage *qrCodeImage;

- (void) setMargin:(NSNumber *)margin {
    if (margin.intValue > 20) {
        margin = @(20);
        BNCLogWarning(@"Margin was reduced to the maximum of 20.");
    }
    if (margin.intValue < 1) {
        margin = @(1);
        BNCLogWarning(@"Margin was increased to the minimum of 1.");
    }
    _margin = margin;
}

- (void) setWidth:(NSNumber *)width {
    if (width.intValue > 2000) {
        width = @(2000);
        BNCLogWarning(@"Width was reduced to the maximum of 2000.");
    }
    if (width.intValue < 300) {
        width = @(300);
        BNCLogWarning(@"Width was increased to the minimum of 300.");
    }
    _width = width;
}

- (void) getQRCodeAsData:(BranchUniversalObject*_Nullable)buo
          linkProperties:(BranchLinkProperties*_Nullable)lp
              completion:(void(^)(NSData * _Nullable qrCode, NSError * _Nullable error))completion {
    
    NSMutableDictionary *settings = [NSMutableDictionary new];
    
    if (self.codeColor) { settings[@"code_color"] = [self hexStringForColor:self.codeColor]; }
    if (self.backgroundColor) { settings[@"background_color"] = [self hexStringForColor:self.backgroundColor]; }
    if ([self.margin intValue]) { settings[@"margin"] = self.margin; }
    if ([self.width intValue]) { settings[@"width"] = self.width; }
    
    settings[@"image_format"] = (self.imageFormat == BranchQRCodeImageFormatJPEG) ? @"JPEG" : @"PNG";
    
    if (self.centerLogo) {
        NSData *data=[NSData dataWithContentsOfURL:[NSURL URLWithString: self.centerLogo]];
        CIImage *image=[CIImage imageWithData:data];
        if (image == nil) {
            BNCLogWarning(@"QR code center logo was an invalid URL string.");
        } else {
            settings[@"center_logo_url"] = self.centerLogo;
        }
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (lp.channel) { parameters[@"channel"] = lp.channel; }
    if (lp.feature) { parameters[@"feature"] = lp.feature; }
    if (lp.campaign) { parameters[@"campaign"] = lp.campaign; }
    if (lp.stage) { parameters[@"stage"] = lp.stage; }
    if (lp.tags) { parameters[@"tags"] = lp.tags; }
    
    parameters[@"qr_code_settings"] = settings;
    parameters[@"data"] = [buo dictionary];
    parameters[@"branch_key"] = [Branch.sharedInstance getKey];
        
    NSData *cachedQRCode = [[BNCQRCodeCache sharedInstance] checkQRCodeCache:parameters];
    if (cachedQRCode) {
        completion(cachedQRCode, nil);
        return;
    }
    
    [self callQRCodeAPI:parameters completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error){
        if (completion != nil) {
            if (qrCode != nil) {
                [[BNCQRCodeCache sharedInstance] addQRCodeToCache:qrCode withParams:parameters];
            }
            completion(qrCode, error);
        }
    }];
}

- (void)getQRCodeAsImage:(BranchUniversalObject *)buo
          linkProperties:(BranchLinkProperties *)lp
              completion:(void (^)(CIImage * _Nonnull, NSError * _Nonnull))completion {
    
    [self getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nullable error) {
        if (completion != nil) {
            if (error) {
                CIImage *img = [CIImage new];
                completion(img, error);
            } else {
                CIImage *qrCodeImage =  [CIImage imageWithData:qrCode];
                completion(qrCodeImage, error);
            }
        }
    }];
}

- (void) callQRCodeAPI:(NSDictionary*_Nullable)params
            completion:(void(^)(NSData * _Nullable qrCode, NSError * _Nullable error))completion {
    
    NSError *error;
    NSString *branchAPIURL = [[BranchConfiguration init] branchAPIServiceURL];
    NSString *urlString = [NSString stringWithFormat: @"%@/v1/qr-code", branchAPIURL];
    NSURL *url = [NSURL URLWithString: urlString];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSString *requestString = [self.class formattedStringWithData:request.HTTPBody];
    BNCLogDebug(@"Network start POST to v1/qr-code: %@", requestString);
    NSDate *startDate = [NSDate date];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            BNCLogError(@"%@", [NSString stringWithFormat:@"QR Code Post Request Error: %@", [error localizedDescription]]);
            completion(nil, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode == 200) {
            
            BNCLogDebug(@"Network finish operation %@ %1.3fs. Status %ld.",
                        request.URL.absoluteString,
                        - [startDate timeIntervalSinceNow],
                        (long)httpResponse.statusCode);
            
            completion(data, nil);
        } else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            BNCLogError(@"%@", [NSString stringWithFormat:@"Error with response and Status Code %ld: %@", (long)httpResponse.statusCode, responseDictionary]);
            error = [NSError branchErrorWithCode: BNCBadRequestError localizedMessage: responseDictionary[@"message"]];
            
            completion(nil, error);
        }
    }];
    
    [postDataTask resume];
}

- (BOOL)isValidUrl:(NSString *)urlString{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    return [NSURLConnection canHandleRequest:request];
}

- (NSString *)hexStringForColor:(NSColor *)color {
    CGColorSpaceModel colorSpace = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r, g, b;
    
    if (colorSpace == kCGColorSpaceModelMonochrome) {
        r = components[0];
        g = components[0];
        b = components[0];
    }
    else {
        r = components[0];
        g = components[1];
        b = components[2];
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)
    ];
}

+ (NSString*) formattedStringWithData:(NSData*)data {
    if (!data) return nil;
    NSString*responseString = nil;
    @try {
        NSDictionary*dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dictionary) {
            NSData*formattedData = [NSJSONSerialization dataWithJSONObject:dictionary options:3 error:nil];
            if (formattedData)
                responseString = [[NSString alloc] initWithData:formattedData encoding:NSUTF8StringEncoding];
        }
        if (!responseString)
            responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!responseString)
            responseString = data.description;
    }
    @catch(id error) {
    }
    return responseString;
}

@end
