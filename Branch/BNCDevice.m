/**
 @file          BNCDevice.m
 @package       Branch-SDK
 @brief         Device information.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

/**
  @discussion

  Technical Note TN1103
  Uniquely Identifying a Macintosh Computer
  https://developer.apple.com/library/content/technotes/tn1103/_index.html
*/

#import "BNCDevice.h"
#import "BNCLog.h"

#import <AppKit/Appkit.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/utsname.h>

// Forward declare this for older versions of iOS
@interface NSLocale (BranchAvailability)
- (NSString*) countryCode;
- (NSString*) languageCode;
@end

#pragma mark - BRNNetworkInfo

typedef NS_ENUM(NSInteger, BNCNetworkAddressType) {
    BNCNetworkAddressTypeUnknown = 0,
    BNCNetworkAddressTypeIPv4,
    BNCNetworkAddressTypeIPv6
};

@interface BNCNetworkInterface : NSObject

+ (NSArray<BNCNetworkInterface*>*) currentInterfaces;

@property (nonatomic, strong) NSString              *interfaceName;
@property (nonatomic, assign) BNCNetworkAddressType addressType;
@property (nonatomic, strong) NSString              *address;
@end

@implementation BNCNetworkInterface

+ (NSArray<BNCNetworkInterface*>*) currentInterfaces {

    struct ifaddrs *interfaces = NULL;
    NSMutableArray *currentInterfaces = [NSMutableArray arrayWithCapacity:8];

    // Retrieve the current interfaces - returns 0 on success

    if (getifaddrs(&interfaces) != 0) {
        int e = errno;
        BNCLogError(@"Can't read ip address: (%d): %s.", e, strerror(e));
        goto exit;
    }

    // Loop through linked list of interfaces --

    struct ifaddrs *interface = NULL;
    for(interface=interfaces; interface; interface=interface->ifa_next) {
        // BNCLogDebugSDK(@"Found %s: %x.", interface->ifa_name, interface->ifa_flags);
        // Check the state: IFF_RUNNING, IFF_UP, IFF_LOOPBACK, etc.
        if ((interface->ifa_flags & IFF_UP) &&
            (interface->ifa_flags & IFF_RUNNING) &&
            !(interface->ifa_flags & IFF_LOOPBACK)) {
        } else {
            continue;
        }

        // TODO: Check ifdata too.
        // struct if_data *ifdata = interface->ifa_data;

        const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
        if (!addr) continue;

        BNCNetworkAddressType type = BNCNetworkAddressTypeUnknown;
        char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];

        if (addr->sin_family == AF_INET) {
            if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN))
                type = BNCNetworkAddressTypeIPv4;
        }
        else
        if (addr->sin_family == AF_INET6) {
            const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
            if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN))
                type = BNCNetworkAddressTypeIPv6;
        }
        else {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
        if (name && type != BNCNetworkAddressTypeUnknown) {
            BNCNetworkInterface *interface = [BNCNetworkInterface new];
            interface.interfaceName = name;
            interface.addressType = type;
            interface.address = [NSString stringWithUTF8String:addrBuf];
            [currentInterfaces addObject:interface];
        }
    }

exit:
    if (interfaces) freeifaddrs(interfaces);
    return currentInterfaces;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p %@ %@>",
        NSStringFromClass(self.class),
        self,
        self.interfaceName,
        self.address
    ];
}

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

+ (NSString*)country {

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
    //NSString* language = [[NSLocale preferredLanguages] firstObject];
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

+ (NSString*) userAgentString {
    return @"";
}

+ (NSData*) macAddress {
    // Generating and hashing a MAC address:
    //
    // https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14

    kern_return_t             kernResult;
    mach_port_t               master_port;
    CFMutableDictionaryRef    matchingDict;
    io_iterator_t             iterator;
    io_object_t               service;
    CFDataRef                 macAddress = nil;

    kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
    if (kernResult != KERN_SUCCESS) {
        BNCLogDebugSDK(@"IOMasterPort returned %d.", kernResult);
        return nil;
    }

    matchingDict = IOBSDNameMatching(master_port, 0, "en0");
    if (!matchingDict) {
        BNCLogDebugSDK(@"IOBSDNameMatching returned empty dictionary.");
        return nil;
    }

    kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
    if (kernResult != KERN_SUCCESS) {
        BNCLogDebugSDK(@"IOServiceGetMatchingServices returned %d.", kernResult);
        return nil;
    }

    while((service = IOIteratorNext(iterator)) != 0) {
        io_object_t parentService;

        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane,
                &parentService);
        if (kernResult == KERN_SUCCESS) {
            if (macAddress) CFRelease(macAddress);

            macAddress = (CFDataRef) IORegistryEntryCreateCFProperty(parentService,
                    CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
            IOObjectRelease(parentService);
        } else {
            BNCLogDebugSDK(@"IORegistryEntryGetParentEntry returned %d.", kernResult);
        }

        IOObjectRelease(service);
    }
    IOObjectRelease(iterator);

    return (__bridge_transfer NSData*) macAddress;
}

+ (NSString*) hardwareID {
    NSData*data = [self macAddress];
    if (!data || data.length != 6) return nil;
    const unsigned char *b = data.bytes;
    NSString*string = [NSString stringWithFormat:@"%x:%x:%x:%x:%x:%x", b[0], b[1], b[2], b[3], b[4], b[5]];
    return string;
}

/*
+ (NSString*) userAgentString {

    static NSString* brn_browserUserAgentString = nil;

    void (^setBrowserUserAgent)(void) = ^() {
        @synchronized (self) {
            if (!brn_browserUserAgentString) {
                brn_browserUserAgentString =
                    [[[UIWebView alloc]
                      initWithFrame:CGRectZero]
                        stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
                preferences.browserUserAgentString = brn_browserUserAgentString;
                preferences.lastSystemBuildVersion = self.systemBuildVersion;
                BNCLogDebugSDK(@"userAgentString: '%@'.", brn_browserUserAgentString);
            }
        }
    };

    NSString* (^browserUserAgent)(void) = ^ NSString* () {
        @synchronized (self) {
            return brn_browserUserAgentString;
        }
    };

    @synchronized (self) {
        //    We only get the string once per app run:

        if (brn_browserUserAgentString)
            return brn_browserUserAgentString;

        //  Did we cache it?

        BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
        if (preferences.browserUserAgentString &&
            preferences.lastSystemBuildVersion &&
            [preferences.lastSystemBuildVersion isEqualToString:self.systemBuildVersion]) {
            brn_browserUserAgentString = [preferences.browserUserAgentString copy];
            return brn_browserUserAgentString;
        }

        //    Make sure this executes on the main thread.
        //    Uses an implied lock through dispatch_queues:  This can deadlock if mis-used!

        if (NSThread.isMainThread) {
            setBrowserUserAgent();
            return brn_browserUserAgentString;
        }

    }

    //  Different case for iOS 7.0:
    if ([UIDevice currentDevice].systemVersion.doubleValue  < 8.0) {
        BNCLogDebugSDK(@"Getting iOS 7 UserAgent.");
        dispatch_sync(dispatch_get_main_queue(), ^ {
            setBrowserUserAgent();
        });
        BNCLogDebugSDK(@"Got iOS 7 UserAgent.");
        return browserUserAgent();
    }

    //    Wait and yield to prevent deadlock:
    int retries = 10;
    int64_t timeoutDelta = (dispatch_time_t)((long double)NSEC_PER_SEC * (long double)0.100);
    while (!browserUserAgent() && retries > 0) {

        dispatch_block_t agentBlock = dispatch_block_create_with_qos_class(
            DISPATCH_BLOCK_DETACHED | DISPATCH_BLOCK_ENFORCE_QOS_CLASS,
            QOS_CLASS_USER_INTERACTIVE,
            0,  ^ {
                BNCLogDebugSDK(@"Will set userAgent.");
                setBrowserUserAgent();
                BNCLogDebugSDK(@"Did set userAgent.");
            });
        dispatch_async(dispatch_get_main_queue(), agentBlock);

        dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW, timeoutDelta);
        dispatch_block_wait(agentBlock, timeoutTime);
        retries--;
    }
    BNCLogDebugSDK(@"Retries: %d", 10-retries);

    return browserUserAgent();
}
*/

+ (void) updateScreenAttributesWithDevice:(BNCDevice*)device {
    if (!device) return;
    NSDictionary*attributes = [[NSScreen mainScreen] deviceDescription];
    CGSize size = [[attributes valueForKey:NSDeviceSize] sizeValue];
    CGSize resolution = [[attributes valueForKey:NSDeviceResolution] sizeValue];
    device->_screenSize = size;
    device->_screenScale = resolution.width;
}

+ (instancetype) createCurrentDevice {
    BNCDevice*device = [[BNCDevice alloc] init];
    if (!device) return device;

    device->_hardwareID = [self hardwareID];
    if (device->_hardwareID.length == 0) {
        device->_hardwareID = [[NSUUID UUID] UUIDString];
        device->_hardwareIDType = @"random";
    } else
        device->_hardwareIDType = @"idfv";
    device->_brandName = @"Apple";
    device->_modelName = [self modelName];
    device->_systemName = @"macOS";
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
            device->_adID = [uuid UUIDString];
            // limit ad tracking is enabled. iOS 10+
            if ([device->_adID isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                device->_adID = nil;
            }
        }

        #pragma clang diagnostic pop
    }

    device->_country = [self country];
    device->_language = [self language];
    device->_browserUserAgent = [self userAgentString];

    device->_deviceIsUnidentified =
        ([device->_hardwareIDType isEqualToString:@"random"] && device->_adID == nil);

    return device;
}

#pragma mark - Instance Methods

//- (NSString *)vendorID {
//    @synchronized (self) {
//        if (_vendorID) return _vendorID;
//        /*
//         * https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
//         * BNCSystemObserver.getVendorId is based on UIDevice.identifierForVendor. Note from the
//         * docs above:
//         *
//         * If the value is nil, wait and get the value again later. This happens, for example,
//         * after the device has been restarted but before the user has unlocked the device.
//         *
//         * It's not clear if that specific example scenario would apply to opening Branch links,
//         * but this lazy initialization is probably safer.
//         */
//        _vendorID = [BNCSystemObserver getVendorId].copy;
//        return _vendorID;
//    }
//}

- (NSDictionary*) v2dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCFieldDefinesDictionaryFromSelf
    #include "BNCFieldDefines.h"

    addString(systemName,           os);
    addString(systemVersion,        os_version);
//  addString(extensionType,        environment);
//  addString(vendorID,             idfv);
    addString(adID,                 idfa);
    addString(browserUserAgent,     user_agent);
    addString(country,              country);
    addString(language,             language);
    addString(brandName,            brand);
//  addString(applicationVersion,   app_version);
    addString(modelName,            model);
    addDouble(screenScale,          screen_dpi);
    addDouble(screenSize.height,    screen_height);
    addDouble(screenSize.width,     screen_width);
    addBoolean(deviceIsUnidentified, unidentified_device);
    addString(localIPAddress,       local_ip);

    #include "BNCFieldDefines.h"

    if (!self.adTrackingIsEnabled)
        dictionary[@"limit_ad_tracking"] = CFBridgingRelease(kCFBooleanTrue);
/*
    NSString *s = nil;
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];

    s = preferences.userIdentity;
    if (s.length) dictionary[@"developer_identity"] = s;

    s = preferences.deviceFingerprintID;
    if (s.length) dictionary[@"device_fingerprint_id"] = s;

    if (preferences.limitFacebookTracking)
        dictionary[@"limit_facebook_tracking"] = CFBridgingRelease(kCFBooleanTrue);

    dictionary[@"sdk"] = @"ios";
    dictionary[@"sdk_version"] = BNC_SDK_VERSION;
*/
    return dictionary;
}

- (NSString*) localIPAddress {
    @synchronized (self) {
        NSArray<BNCNetworkInterface*>*interfaces = [BNCNetworkInterface currentInterfaces];
        for (BNCNetworkInterface *interface in interfaces) {
            if (interface.addressType == BNCNetworkAddressTypeIPv4)
                return interface.address;
        }
        return nil;
    }
}

- (NSArray<NSString*>*) allIPAddresses {
    @synchronized(self) {
        NSMutableArray *array = [NSMutableArray new];
        for (BNCNetworkInterface *inf in [BNCNetworkInterface currentInterfaces]) {
            [array addObject:inf.description];
        }
        return array;
    }
}

@end
