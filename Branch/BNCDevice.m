/**
 @file          BNCDevice.m
 @package       Branch
 @brief         Device information.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCDevice.h"
#import "BNCLog.h"
#import "BNCNetworkInformation.h"

#import <sys/sysctl.h>
#import <CommonCrypto/CommonCrypto.h>

// Forward declare this for older versions of iOS
@interface NSLocale (Branch)
- (NSString*) countryCode;
- (NSString*) languageCode;
@end

#pragma mark - BNCDevice

@interface BNCDevice() {
    NSString*_vendorID;
}
@end

@implementation BNCDevice

#pragma mark - Class Methods

+ (BNCDevice*) currentDevice {
    static BNCDevice *currentDevice = 0;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        currentDevice = [self createCurrentDevice];
    });
    return currentDevice;
}

+ (NSString *)modelName {
    NSString*modelName = nil;
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        modelName = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
    }
    return modelName;
}

+ (NSString*) systemName {
    #if TARGET_OS_OSX
    return @"mac_OS";
    #elif TARGET_OS_IOS
    return @"iOS";
    #elif TARGET_OS_TV
    return @"tv_OS";
    #elif TARGET_OS_WATCH
    return @"watch_OS";
    #else
    return @"Unknown";
    #endif
}

+ (BOOL) isSimulator {
    #if TARGET_OS_SIMULATOR
    return YES;
    #else
    return NO;
    #endif
}

+ (NSString*) country {

    NSString *country = nil;
    #define returnIfValidCountry() \
        if ([country isKindOfClass:[NSString class]] && country.length) { \
            return country; \
        } else { \
            country = nil; \
        }

    // Should work on iOS 10
    NSLocale *currentLocale = [NSLocale currentLocale];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpartial-availability"
    if ([currentLocale respondsToSelector:@selector(countryCode)]) {
        country = [currentLocale countryCode];
    }
    #pragma clang diagnostic pop
    returnIfValidCountry();

    // Should work on iOS 9
    NSString *rawLanguage = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:rawLanguage];
    country = [languageDictionary objectForKey:@"kCFLocaleCountryCodeKey"];
    returnIfValidCountry();

    // Should work on iOS 8 and below.
    // NSString* language = [[NSLocale preferredLanguages] firstObject];
    NSString *rawLocale = currentLocale.localeIdentifier;
    NSRange range = [rawLocale rangeOfString:@"_"];
    if (range.location != NSNotFound) {
        range = NSMakeRange(range.location+1, rawLocale.length-range.location-1);
        country = [rawLocale substringWithRange:range];
    }
    returnIfValidCountry();

    #undef returnIfValidCountry

    return nil;
}

+ (NSString*) language {

    NSString *language = nil;
    #define returnIfValidLanguage() \
        if ([language isKindOfClass:[NSString class]] && language.length) { \
            return language; \
        } else { \
            language = nil; \
        } \

    // Should work on iOS 10
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpartial-availability"
    NSLocale *currentLocale = [NSLocale currentLocale];
    if ([currentLocale respondsToSelector:@selector(languageCode)]) {
        language = [currentLocale languageCode];
    }
    #pragma clang diagnostic pop
    returnIfValidLanguage();

    // Should work on iOS 9
    NSString *rawLanguage = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:rawLanguage];
    language = [languageDictionary  objectForKey:@"kCFLocaleLanguageCodeKey"];
    returnIfValidLanguage();

    // Should work on iOS 8 and below.
    language = [[NSLocale preferredLanguages] firstObject];
    returnIfValidLanguage();

    #undef returnIfValidLanguage

    return nil;
}

+ (NSString*) systemBuildVersion {
    int mib[2] = { CTL_KERN, KERN_OSVERSION };
    u_int namelen = sizeof(mib) / sizeof(mib[0]);

    //    Get the size for the buffer --
    size_t bufferSize = 0;
    sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
    if (bufferSize <= 0) return nil;

    u_char buildBuffer[bufferSize];
    int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);

    NSString *version = nil;
    if (result >= 0) {
        version = [[NSString alloc]
            initWithBytes:buildBuffer
            length:bufferSize-1
            encoding:NSUTF8StringEncoding];
    }
    return version;
}

+ (NSString*) networkAddress {
    NSMutableString* string = nil;
    BNCNetworkInformation*info = [BNCNetworkInformation local];
    NSData*data = info.address;
    if (!data || data.length != 6) return nil;

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (const unsigned int) data.length, digest);

    // SHA1 is 160 bits = 20 bytes

    string = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x", digest[i]];

    // Truncate last four bytes to make UUID:

    if (string.length < 32) return nil; // What?
    NSString*result = [NSString stringWithFormat:@"mac_%@", string];

    return result;
}

#if TARGET_OS_OSX

+ (void) updateScreenAttributesWithDevice:(BNCDevice*)device {
    if (!device) return;
    NSDictionary*attributes = [[NSScreen mainScreen] deviceDescription];
    CGSize size = [[attributes valueForKey:NSDeviceSize] sizeValue];
    CGSize resolution = [[attributes valueForKey:NSDeviceResolution] sizeValue];
    device->_screenSize = size;
    device->_screenDPI = resolution.width;
}

#else

+ (void) updateScreenAttributesWithDevice:(BNCDevice*)device {
    if (!device) return;
    device->_screenSize = [UIScreen mainScreen].bounds.size;
    device->_screenDPI = [UIScreen mainScreen].scale;
}

#endif

+ (instancetype) createCurrentDevice {
    BNCDevice*device = [[BNCDevice alloc] init];
    if (!device) return device;

    device->_brandName = @"Apple";
    device->_modelName = [self modelName];
    device->_systemName = [self systemName];
    device->_isSimulator = [self isSimulator];
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    device->_systemVersion =
        [NSString stringWithFormat:@"%ld.%ld.%ld",
            (long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
    device->_systemBuildVersion = [self systemBuildVersion];
    [self updateScreenAttributesWithDevice:device];

    device->_adTrackingIsEnabled = NO;
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    SEL advertisingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
    SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
    if (ASIdentifierManagerClass && [ASIdentifierManagerClass respondsToSelector:sharedManagerSelector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        id sharedManager = [ASIdentifierManagerClass performSelector:sharedManagerSelector];
        if ([sharedManager respondsToSelector:advertisingEnabledSelector]) {
            device->_adTrackingIsEnabled = (BOOL) [sharedManager performSelector:advertisingEnabledSelector];
        }
        if ([sharedManager respondsToSelector:advertisingIdentifierSelector]) {
            NSUUID *uuid = [sharedManager performSelector:advertisingIdentifierSelector];
            device->_advertisingID = [uuid UUIDString];
            // Check if limit ad tracking is enabled. iOS 10+
            if ([device->_advertisingID isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                device->_advertisingID = nil;
            }
        }

        #pragma clang diagnostic pop
    }
    device->_netAddress = [self networkAddress];
    device->_country = [self country];
    device->_language = [self language];

    return device;
}

#pragma mark - Instance Methods

#if TARGET_OS_OSX

- (NSString *)vendorID {
    return nil;
}

#else

- (NSString *)vendorID {
    /*
     * https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
     *
     * If the value is nil, wait and get the value again later. This happens, for example,
     * after the device has been restarted but before the user has unlocked the device.
     *
     * It's not clear if that specific example scenario would apply to opening Branch links,
     * but this lazy initialization is probably safer.
     */
    @synchronized (self) {
        static NSString* _vendorID = nil;
        if (!_vendorID) {
            _vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        return _vendorID;
    }
}

#endif

- (NSString*) hardwareID {
    NSString*s;
    s = [self netAddress];
    if (s) {
        _hardwareIDType = @"mac_id";
        return s;
    }
    s = [self advertisingID];
    if (s) {
        _hardwareIDType = @"idfa";
        return s;
    }
    s = [self vendorID];
    if (s) {
        _hardwareIDType = @"vendor_id";
        return s;
    }
    s = [[NSUUID UUID] UUIDString];
    _hardwareIDType = @"random";
    return s;
}

- (BOOL) deviceIsUnidentified {
    if (self.advertisingID == nil &&
        self.netAddress == nil &&
        self.vendorID == nil)
        return YES;
    return NO;
}

- (NSMutableDictionary*) v1dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(systemName,           os);
    addString(systemVersion,        os_version);
    addString(hardwareID,           hardware_id);
    addString(hardwareIDType,       hardware_id_type);
    addString(vendorID,             idfv);
    addString(advertisingID,        idfa);
    addString(netAddress,           mac_id);
    addString(country,              country);
    addString(language,             language);
    addString(brandName,            brand);
    addString(modelName,            model);
    addDouble(screenDPI,            screen_dpi);
    addDouble(screenSize.height,    screen_height);
    addDouble(screenSize.width,     screen_width);
    addBoolean(deviceIsUnidentified, unidentified_device);
    addString(localIPAddress,       local_ip);
    addString(systemName,           os);

    if (!self.deviceIsUnidentified)
        dictionary[@"is_hardware_id_real"] = BNCWireFormatFromBool(YES);

    return dictionary;
}

- (NSMutableDictionary*) v2dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(systemName,           os);
    addString(systemVersion,        os_version);
    addString(vendorID,             idfv);
    addString(advertisingID,        idfa);
    addString(netAddress,           mac_id);
    addString(country,              country);
    addString(language,             language);
    addString(brandName,            brand);
    addString(modelName,            model);
    addDouble(screenDPI,            screen_dpi);
    addDouble(screenSize.height,    screen_height);
    addDouble(screenSize.width,     screen_width);
    addBoolean(deviceIsUnidentified, unidentified_device);
    addString(localIPAddress,       local_ip);

    return dictionary;
}

- (NSString*) localIPAddress {
    @synchronized (self) {
        NSArray<BNCNetworkInformation*>*interfaces = [BNCNetworkInformation currentInterfaces];
        for (BNCNetworkInformation *interface in interfaces) {
            if (interface.inetAddressType == BNCInetAddressTypeIPv4)
                return interface.displayInetAddress;
        }
        return @"";
    }
}

- (NSArray<NSString*>*) allLocalIPAddresses {
    @synchronized(self) {
        NSMutableArray *array = [NSMutableArray new];
        for (BNCNetworkInformation *inf in [BNCNetworkInformation currentInterfaces]) {
            if (inf.displayInetAddress.length)
                [array addObject:inf.displayInetAddress];
        }
        return array;
    }
}

@end
