/**
 @file          BNCDevice.h
 @package       Branch-SDK
 @brief         Device information.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCDevice : NSObject

+ (instancetype) currentDevice;
- (NSMutableDictionary*) v1dictionary;
- (NSMutableDictionary*) v2dictionary;

@property (atomic, copy, readonly) NSString *hardwareID;
@property (atomic, copy, readonly) NSString *hardwareIDType;        //!< vendor_id, idfa, or random
@property (atomic, assign, readonly) BOOL    deviceIsUnidentified;
@property (atomic, copy, readonly) NSString *brandName;
@property (atomic, copy, readonly) NSString *modelName;
@property (atomic, copy, readonly) NSString *systemName;
@property (atomic, copy, readonly) NSString *systemVersion;
@property (atomic, copy, readonly) NSString *systemBuildVersion;
@property (atomic, assign, readonly) BOOL    isSimulator;
@property (atomic, assign, readonly) CGSize  screenSize;
@property (atomic, assign, readonly) CGFloat screenDPI;
@property (atomic, assign, readonly) BOOL    adTrackingIsEnabled;      //!< True if advertisingID is available.
@property (atomic, copy,   readonly) NSString*_Nullable advertisingID;
@property (atomic, copy,   readonly) NSString*_Nullable vendorID;   //!< iOS identifierForVendor
@property (atomic, copy, readonly) NSString *country;               //!< The iso2 Country name (us, in,etc).
@property (atomic, copy, readonly) NSString *language;              //!< The iso2 language code (en, ml).
@property (atomic, copy, readonly) NSString *browserUserAgent;      //!< Simple user agent string.
@property (atomic, copy, readonly) NSString *localIPAddress;        //!< The current local IPv4 address.
@property (atomic, copy, readonly) NSArray<NSString*> *allIPAddresses; //!< All local IP addresses.
@end

NS_ASSUME_NONNULL_END
