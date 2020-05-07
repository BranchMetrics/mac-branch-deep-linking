/**
 @file          BNCNetworkInformation.m
 @package       Branch
 @brief         This class retreives information about the local network.

 @author        Edward Smith
 @date          August 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCNetworkInformation.h"
#import "BNCLog.h"

#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

#if TARGET_OS_TV || TARGET_OS_IPHONE
    #import "../Vendor/route.h"
#else
    #import <net/route.h>
    #import <netinet/if_ether.h>
#endif

#define ROUNDUP(a) \
    ((a) > 0 ? (1 + (((a) - 1) | (sizeof(uint32_t) - 1))) : sizeof(uint32_t))

@interface BNCNetworkInformation ()
@property (readwrite) NSString*interface;
@property (readwrite) NSData*address;
@property (readwrite) NSString*displayAddress;
@property (readwrite) NSData*inetAddress;
@property (readwrite) NSString*displayInetAddress;
@property (readwrite) BNCInetAddressType inetAddressType;
@end

@implementation BNCNetworkInformation

+ (NSString*) etherString:(struct sockaddr_dl*)sdl  {
    if (sdl->sdl_alen) {
        u_char *cp = (u_char *)LLADDR(sdl);
        return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
                    cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
    }
    return @"";
}

+ (NSArray<BNCNetworkInformation*>*_Nonnull) areaEntries {
    NSMutableArray<BNCNetworkInformation*>* entries = [NSMutableArray new];
    uint8_t*buffer = NULL;
    size_t buffer_size = 0;
{
    int result;
    uint8_t *buffer_limit, *next;
    char host_buf[NI_MAXHOST];
    char ifix_buf[IF_NAMESIZE];

    int mib[6];
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET6;
    mib[4] = NET_RT_FLAGS;
    mib[5] = RTF_LLINFO;

    result = sysctl(mib, 6, NULL, &buffer_size, NULL, 0);
    if (result < 0 || buffer_size <= 0) {
        BNCLogError(@"sysctl(PF_ROUTE estimate)");
        goto exit;
    }
    buffer = malloc(buffer_size);
    if (!buffer) {
        BNCLogError(@"malloc");
        goto exit;
    }
    result = sysctl(mib, 6, buffer, &buffer_size, NULL, 0);
    if (result < 0) {
        BNCLogError(@"sysctl(PF_ROUTE, NET_RT_FLAGS)");
        goto exit;
    }
    buffer_limit = buffer + buffer_size;

    next = buffer;
    while (next && next < buffer_limit) {
        struct rt_msghdr *rtm = (struct rt_msghdr *) next;
        next += rtm->rtm_msglen;

        struct sockaddr_in6 *sin = (struct sockaddr_in6 *)(rtm + 1);
        struct sockaddr_dl  *sdl = (struct sockaddr_dl *)((char *)sin + ROUNDUP(sin->sin6_len));

        if (sdl->sdl_family != AF_LINK)
            continue;
        if (IN6_IS_ADDR_MULTICAST(&sin->sin6_addr))
            continue;
        if (IN6_IS_ADDR_LINKLOCAL(&sin->sin6_addr) || IN6_IS_ADDR_MC_LINKLOCAL(&sin->sin6_addr)) {
            if (sin->sin6_scope_id == 0)
                sin->sin6_scope_id = sdl->sdl_index;
            // /* KAME specific hack; removed the embedded id */
            // *(u_int16_t *)&sin->sin6_addr.s6_addr[2] = 0;
        }
        getnameinfo(
            (struct sockaddr *)sin,
            sin->sin6_len,
            host_buf,
            sizeof(host_buf),
            NULL,
            0,
            NI_WITHSCOPEID | NI_NUMERICHOST
        );

        char*ifname = if_indextoname(sdl->sdl_index, ifix_buf);
        BNCNetworkInformation*entry = [BNCNetworkInformation new];
        entry.interface = (ifname) ? [NSString stringWithUTF8String:ifname] : @"";
        entry.inetAddress = [NSData dataWithBytes:&sin->sin6_addr length:sizeof(sin->sin6_addr)];
        entry.displayInetAddress = [NSString stringWithUTF8String:host_buf];
        entry.inetAddressType = BNCInetAddressTypeIPv6;
        entry.address = [NSData dataWithBytes:sdl length:6];
        entry.displayAddress = [self etherString:sdl];
        [entries addObject:entry];
    }
}

exit:
    if (buffer) free(buffer);
    return entries;
}

+ (NSArray<BNCNetworkInformation*>*) currentInterfaces {

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

        BNCInetAddressType type = BNCInetAddressTypeUnknown;
        NSData*addressData = nil;
        char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];

        if (addr->sin_family == AF_INET) {
            if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                type = BNCInetAddressTypeIPv4;
                addressData = [NSData dataWithBytes:&addr->sin_addr length:4];
            }
        }
        else
        if (addr->sin_family == AF_INET6) {
            const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
            if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                type = BNCInetAddressTypeIPv6;
                addressData = [NSData dataWithBytes:&addr6->sin6_addr length:sizeof(addr6->sin6_addr)];
            }
        }
        else {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
        if (name && type != BNCInetAddressTypeUnknown) {
            BNCNetworkInformation *interface = [BNCNetworkInformation new];
            interface.interface = name;
            interface.inetAddress = addressData;
            interface.inetAddressType = type;
            interface.displayInetAddress = [NSString stringWithUTF8String:addrBuf];
            [currentInterfaces addObject:interface];
        }
    }

exit:
    if (interfaces) freeifaddrs(interfaces);
    return currentInterfaces;
}

// returns first local network interface
+ (BNCNetworkInformation*) local {
    NSArray*areaEntries = [self areaEntries];
    NSArray*localEntries = [self currentInterfaces];
    for (BNCNetworkInformation*le in localEntries) {
        for (BNCNetworkInformation*ae in areaEntries) {
            if (![self isTouchBarInterface:ae] && [self canMergeLocalEntry:le withAreaEntry:ae]) {
                le.address = ae.address;
                le.displayAddress = ae.displayAddress;
                return le;
            }
        }
    }
    return nil;
}

// Ignore the Touchbar iBridge interface on the MacBook Pro
+ (BOOL)isTouchBarInterface:(BNCNetworkInformation *)ae {
    NSString *touchBarMacAddress = @"ac:de:48:00:11:22";
    if ([touchBarMacAddress isEqualToString:ae.displayAddress]) {
        return YES;
    }
    return NO;
}

// Check if we can merge the entries
+ (BOOL)canMergeLocalEntry:(BNCNetworkInformation *)le withAreaEntry:(BNCNetworkInformation *)ae {
    
    // fairly certain this IP address check never works
    if (ae.inetAddress && le.inetAddress && [ae.inetAddress isEqualToData:le.inetAddress]) {
        return YES;
    }
    
    // This IP address compare works
    uint8_t const kLocalAddress[] = { 0xfe, 0x80 };
    if (ae.inetAddress.length == 16 &&
        le.inetAddress.length == 16 &&
        memcmp([ae.inetAddress bytes], kLocalAddress, 2) == 0 &&
        memcmp([le.inetAddress bytes], kLocalAddress, 2) == 0 &&
        memcmp([le.inetAddress bytes] + 8, [ae.inetAddress bytes] + 8, 8) == 0) {
        return YES;
    }
    
    return NO;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p %@ %@ %@>",
        NSStringFromClass(self.class),
        (const void*) self,
        self.interface,
        self.displayAddress.length ? self.displayAddress : @"(incomplete)",
        self.displayInetAddress.length ? self.displayInetAddress : @"(none)"];
}

@end
