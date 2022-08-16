//
//  BNCQRCodeCache.h
//  BranchMacOS
//
//  Created by Nipun Singh on 5/24/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BranchHeader.h"

#ifndef BNCQRCodeCache_h
#define BNCQRCodeCache_h

@interface BNCQRCodeCache : NSObject

+ (BNCQRCodeCache *) sharedInstance;
- (void)addQRCodeToCache:(NSData *)qrCodeData withParams:(NSMutableDictionary *)parameters;
- (NSData *)checkQRCodeCache:(NSMutableDictionary *)parameters;

@end

#endif /* BNCQRCodeCache_h */
