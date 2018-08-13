/**
 @file          BNCDevice.m
 @package       Branch
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

#import <sys/sysctl.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/utsname.h>
#import <CommonCrypto/CommonCrypto.h>
#import <sys/ioctl.h>
#import "../Vendor/route.h"

// Forward declare this for older versions of iOS
@interface NSLocale (Branch)
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

        // TODO: Check ifdata too. May indicate actual interface used.
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

#if TARGET_OS_TV

static int rdomain;
#define    RTF_LLINFO    0x400        /* generated by link layer (e.g. ARP) */
/* packing rule for routing socket */
#define ROUNDUP(a) \
    ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

+ (NSData*) macAddress {

    //dump(struct in6_addr *addr, int cflag)
    struct in6_addr *addr;
    int cflag;

    int mib[7];
    size_t needed;
    char *lim, *buf = NULL, *next;

    struct rt_msghdr *rtm;
    struct sockaddr_in6 *sin;
    struct sockaddr_dl *sdl;
    struct in6_nbrinfo *nbi;
    struct timeval now;
    int addrwidth;
    int llwidth;
    int ifwidth;
    char *ifname;

    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET6;
    mib[4] = NET_RT_FLAGS;
    mib[5] = RTF_LLINFO;
    mib[6] = rdomain;
    while (1) {
        if (sysctl(mib, 7, NULL, &needed, NULL, 0) == -1)
            err(1, "sysctl(PF_ROUTE estimate)");
        if (needed == 0)
            break;
        if ((buf = realloc(buf, needed)) == NULL)
            err(1, "realloc");
        if (sysctl(mib, 7, buf, &needed, NULL, 0) == -1) {
            if (errno == ENOMEM)
                continue;
            err(1, "sysctl(PF_ROUTE, NET_RT_FLAGS)");
        }
        lim = buf + needed;
        break;
    }

    for (next = buf; next && lim && next < lim; next += rtm->rtm_msglen) {
        int isrouter = 0, prbs = 0;

        rtm = (struct rt_msghdr *)next;
        if (rtm->rtm_version != RTM_VERSION)
            continue;
        sin = (struct sockaddr_in6 *)(next + rtm->rtm_hdrlen);
        sdl = (struct sockaddr_dl *)((char *)sin + ROUNDUP(sin->sin6_len));

        /*
         * Some OSes can produce a route that has the LINK flag but
         * has a non-AF_LINK gateway (e.g. fe80::xx%lo0 on FreeBSD
         * and BSD/OS, where xx is not the interface identifier on
         * lo0).  Such routes entry would annoy getnbrinfo() below,
         * so we skip them.
         * XXX: such routes should have the GATEWAY flag, not the
         * LINK flag.  However, there is rotten routing software
         * that advertises all routes that have the GATEWAY flag.
         * Thus, KAME kernel intentionally does not set the LINK flag.
         * What is to be fixed is not ndp, but such routing software
         * (and the kernel workaround)...
         */
        if (sdl->sdl_family != AF_LINK)
            continue;

        if (!(rtm->rtm_flags & RTF_HOST))
            continue;

        if (addr) {
            if (!IN6_ARE_ADDR_EQUAL(addr, &sin->sin6_addr))
                continue;
            found_entry = 1;
        } else if (IN6_IS_ADDR_MULTICAST(&sin->sin6_addr))
            continue;
        if (IN6_IS_ADDR_LINKLOCAL(&sin->sin6_addr) ||
            IN6_IS_ADDR_MC_LINKLOCAL(&sin->sin6_addr)) {
            /* XXX: should scope id be filled in the kernel? */
            if (sin->sin6_scope_id == 0)
                sin->sin6_scope_id = sdl->sdl_index;
#ifdef __KAME__
            /* KAME specific hack; removed the embedded id */
            *(u_int16_t *)&sin->sin6_addr.s6_addr[2] = 0;
#endif
        }
        getnameinfo((struct sockaddr *)sin, sin->sin6_len, host_buf,
            sizeof(host_buf), NULL, 0, (nflag ? NI_NUMERICHOST : 0));
        if (cflag) {
            if (rtm->rtm_flags & RTF_CLONED)
                delete(host_buf);
            continue;
        }
        gettimeofday(&now, 0);
        if (tflag)
            ts_print(&now);

        addrwidth = strlen(host_buf);
        if (addrwidth < W_ADDR)
            addrwidth = W_ADDR;
        llwidth = strlen(ether_str(sdl));
        if (W_ADDR + W_LL - addrwidth > llwidth)
            llwidth = W_ADDR + W_LL - addrwidth;
        ifname = if_indextoname(sdl->sdl_index, ifix_buf);
        if (!ifname)
            ifname = "?";
        ifwidth = strlen(ifname);
        if (W_ADDR + W_LL + W_IF - addrwidth - llwidth > ifwidth)
            ifwidth = W_ADDR + W_LL + W_IF - addrwidth - llwidth;

        printf("%-*.*s %-*.*s %*.*s", addrwidth, addrwidth, host_buf,
            llwidth, llwidth, ether_str(sdl), ifwidth, ifwidth, ifname);

        /* Print neighbor discovery specific informations */
        nbi = getnbrinfo(&sin->sin6_addr, sdl->sdl_index, 1);
        if (nbi) {
            if (nbi->expire > now.tv_sec) {
                printf(" %-9.9s",
                    sec2str(nbi->expire - now.tv_sec));
            } else if (nbi->expire == 0)
                printf(" %-9.9s", "permanent");
            else
                printf(" %-9.9s", "expired");

            switch (nbi->state) {
            case ND6_LLINFO_NOSTATE:
                 printf(" N");
                 break;
            case ND6_LLINFO_INCOMPLETE:
                 printf(" I");
                 break;
            case ND6_LLINFO_REACHABLE:
                 printf(" R");
                 break;
            case ND6_LLINFO_STALE:
                 printf(" S");
                 break;
            case ND6_LLINFO_DELAY:
                 printf(" D");
                 break;
            case ND6_LLINFO_PROBE:
                 printf(" P");
                 break;
            default:
                 printf(" ?");
                 break;
            }

            isrouter = nbi->isrouter;
            prbs = nbi->asked;
        } else {
            warnx("failed to get neighbor information");
            printf("  ");
        }

        printf(" %s%s%s",
            (rtm->rtm_flags & RTF_LOCAL) ? "l" : "",
            isrouter ? "R" : "",
            (rtm->rtm_flags & RTF_ANNOUNCE) ? "p" : "");

        if (prbs)
            printf(" %d", prbs);

        printf("\n");
    }

    if (repeat) {
        printf("\n");
        fflush(stdout);
        sleep(repeat);
        goto again;
    }

    free(buf);
}

#elif TARGET_OS_OSX

+ (NSData*) macAddress {
    kern_return_t             kernResult;
    mach_port_t               master_port;
    io_iterator_t             iterator;
    io_object_t               service;
    CFDataRef                 macAddress = nil;
    CFMutableDictionaryRef    matchingDict = nil;

    kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
    if (kernResult != KERN_SUCCESS) {
        BNCLogDebugSDK(@"IOMasterPort returned %d.", kernResult);
        return nil;
    }

    matchingDict = IOBSDNameMatching(master_port, 0, "en0");
    if (!matchingDict) {
        BNCLogDebugSDK(@"IOBSDNameMatching returned empty dictionary.");
        goto exit;
    }

    // Note: IOServiceGetMatchingServices releases matchingDict.
    kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
    if (kernResult != KERN_SUCCESS) {
        BNCLogDebugSDK(@"IOServiceGetMatchingServices returned %d.", kernResult);
        goto exit;
    }

    while((service = IOIteratorNext(iterator)) != 0) {
        io_object_t parentService;
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
        if (kernResult == KERN_SUCCESS) {
            if (macAddress) CFRelease(macAddress);
            macAddress = (CFDataRef) IORegistryEntryCreateCFProperty(
                parentService,
                CFSTR("IOMACAddress"),
                kCFAllocatorDefault,
                0
            );
            IOObjectRelease(parentService);
        } else {
            BNCLogDebugSDK(@"IORegistryEntryGetParentEntry returned %d.", kernResult);
        }
        IOObjectRelease(service);
    }
    IOObjectRelease(iterator);

exit:
    //if (matchingDict) CFRelease(matchingDict);  // Already released by IOServiceGetMatchingServices
    return (__bridge_transfer NSData*) macAddress;
}

+ (NSString*) networkAddress {
    NSMutableString* string = nil;
    NSData*data = [self macAddress];
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

#else

+ (NSString*) networkAddress {
    return nil;
}

#endif

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
            // limit ad tracking is enabled. iOS 10+
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
        NSArray<BNCNetworkInterface*>*interfaces = [BNCNetworkInterface currentInterfaces];
        for (BNCNetworkInterface *interface in interfaces) {
            if (interface.addressType == BNCNetworkAddressTypeIPv4)
                return interface.address;
        }
        return @"";
    }
}

- (NSArray<NSString*>*) allLocalIPAddresses {
    @synchronized(self) {
        NSMutableArray *array = [NSMutableArray new];
        for (BNCNetworkInterface *inf in [BNCNetworkInterface currentInterfaces]) {
            [array addObject:inf.description];
        }
        return array;
    }
}

@end
