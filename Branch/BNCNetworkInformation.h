/**
 @file          BNCNetworkInformation.h
 @package       Branch
 @brief         This class retreives information about the local network.

 @author        Edward Smith
 @date          August 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BNCInetAddressType) {
    BNCInetAddressTypeUnknown = 0,
    BNCInetAddressTypeIPv4,
    BNCInetAddressTypeIPv6
};

@interface BNCNetworkInformation : NSObject
+ (BNCNetworkInformation*_Nullable) local;
+ (NSArray<BNCNetworkInformation*>*) areaEntries;
+ (NSArray<BNCNetworkInformation*>*) currentInterfaces;
@property (nonatomic, readonly, strong) NSString*interface;
@property (nonatomic, readonly, strong) NSData*_Nullable address;
@property (nonatomic, readonly, strong) NSString*displayAddress;
@property (nonatomic, readonly, strong) NSData*_Nullable inetAddress;
@property (nonatomic, readonly, strong) NSString*displayInetAddress;
@property (nonatomic, readonly, assign) BNCInetAddressType inetAddressType;
@end

NS_ASSUME_NONNULL_END

