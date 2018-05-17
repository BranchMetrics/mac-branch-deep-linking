/**
 @file          BNCDevice.h
 @package       Branch-SDK
 @brief         Device information.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BNCDevice : NSObject

+ (instancetype) currentDevice;
- (NSDictionary*) v2dictionary;

@property (atomic, copy, readonly) NSString *hardwareID;
@property (atomic, copy, readonly) NSString *hardwareIDType;
@property (atomic, assign, readonly) BOOL    deviceIsUnidentified;
@property (atomic, copy, readonly) NSString *brandName;
@property (atomic, copy, readonly) NSString *modelName;
@property (atomic, copy, readonly) NSString *systemName;
@property (atomic, copy, readonly) NSString *systemVersion;
@property (atomic, copy, readonly) NSString *systemBuildVersion;
@property (atomic, assign, readonly) CGSize  screenSize;
@property (atomic, assign, readonly) CGFloat screenScale;
@property (atomic, assign, readonly) BOOL adTrackingIsEnabled;
@property (atomic, copy,   readonly) NSString *adID;
@property (atomic, copy, readonly) NSString* country;            //!< The iso2 Country name (us, in,etc).
@property (atomic, copy, readonly) NSString* language;           //!< The iso2 language code (en, ml).
@property (atomic, copy, readonly) NSString* browserUserAgent;   //!< Simple user agent string.
@property (atomic, copy, readonly) NSString* localIPAddress;     //!< The current local IP address.
@property (atomic, copy, readonly) NSArray<NSString*> *allIPAddresses; //!< All local IP addresses.
@end

NS_ASSUME_NONNULL_END
