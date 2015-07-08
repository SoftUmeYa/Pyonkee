//
//  SUYNetUtils.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/01.
//
//

#import "SUYNetUtils.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>

@implementation SUYNetUtils

typedef NS_ENUM(NSUInteger, SockAddressFamily) {
    SockAddressFamilyV4,
    SockAddressFamilyV6
};

+ (NSString *)localIpV4AddressesString
{
    NSString *joinedString = [[[SUYNetUtils class] localIpV4Addresses] componentsJoinedByString:@","];
    return joinedString;
}

+ (NSArray *)localIpV4Addresses
{
    return [[SUYNetUtils class] localIpAddressesOf:SockAddressFamilyV4];
}

+ (NSArray *)localIpAddressesOf: (SockAddressFamily)addressFamily
{
    NSMutableArray *ipAddresses = [NSMutableArray array] ;
    
    struct ifaddrs *allInterfaces;
    
    // Get list of all interfaces on the local machine:
    if (getifaddrs(&allInterfaces) == 0) {
        struct ifaddrs *interface;
        
        // For each interface ...
        for (interface = allInterfaces; interface != NULL; interface = interface->ifa_next) {
            unsigned int flags = interface->ifa_flags;
            struct sockaddr *addr = interface->ifa_addr;
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if ((flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) {
                char host[NI_MAXHOST];
                if(addressFamily==SockAddressFamilyV4){
                    if (addr->sa_family == AF_INET) {
                        getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                        [ipAddresses addObject:[[NSString alloc] initWithUTF8String:host]];
                    }
                    
                } else {
                    if (addr->sa_family == AF_INET || addr->sa_family == AF_INET6) {
                        getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                        [ipAddresses addObject:[[NSString alloc] initWithUTF8String:host]];
                    }
                }
                
            }
        }
        
        freeifaddrs(allInterfaces);
    }
    
    for(NSString* str in ipAddresses){
        LgInfo(@"!!! IpAddress: %@", str);
    }
    
    
    return ipAddresses;
}
@end
