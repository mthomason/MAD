//
//  BDHost.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/13/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  From http://www.bdunagan.com/2009/11/28/iphone-tip-no-nshost/
//  MIT license
//

#import "BDHost.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

#if __APPLE__
#import <CFNetwork/CFNetwork.h>
#import <net/ethernet.h>
#import <net/if_dl.h>
#else
#import <netpacket/packet.h>	// sockaddr_ll: Linux's link-layer address
#endif

#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation BDHost

+ (NSString *)addressForHostname:(NSString *)hostname {
	NSArray *addresses = [BDHost addressesForHostname:hostname];
	return addresses.class > 0 ? addresses[0] : nil;
}

+ (NSArray *)addressesForHostname:(NSString *)hostname {
#if __APPLE__
	// Get the addresses for the given hostname.
	CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
	if (!hostRef) return nil;

	Boolean isSuccess = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
	if (!isSuccess) {
		CFRelease(hostRef);
		return nil;
	}

	CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);
	if (addressesRef == nil){
		CFRelease(hostRef);
		return nil;
	}

	// Convert these addresses into strings.
	char ipAddress[INET6_ADDRSTRLEN];
	NSMutableArray *addresses = [NSMutableArray array];
	CFIndex numAddresses = CFArrayGetCount(addressesRef);
	for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
		struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addressesRef, currentIndex));
		if (address == nil) {
			CFRelease(hostRef);
			return nil;
		}
		getnameinfo(address, address->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST);
		//if (ipAddress == nil) return nil;

		// SATOSHI: return only IPv4 address
		// http://h30097.www3.hp.com/docs/base%5Fdoc/DOCUMENTATION/V50A%5FHTML/MAN/MAN7/0052%5F%5F%5F%5F.HTM
		if (address->sa_family == AF_INET) {
			NSString *string = [[NSString alloc] initWithCString:ipAddress encoding:NSASCIIStringEncoding];
			[addresses addObject:string];
		}
	}
	CFRelease(hostRef);
	return addresses;
#else
	// CFHost has no Linux equivalent; getaddrinfo is the same resolution the
	// CF path performs under it.  Only IPv4 addresses, as above.
	struct addrinfo hints;
	struct addrinfo *result = NULL;
	memset(&hints, 0, sizeof(hints));
	hints.ai_family   = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	if (getaddrinfo(hostname.UTF8String, NULL, &hints, &result) != 0) {
		return nil;
	}

	char ipAddress[INET6_ADDRSTRLEN];
	NSMutableArray *addresses = [NSMutableArray array];
	for (struct addrinfo *current = result; current != NULL; current = current->ai_next) {
		if (current->ai_family != AF_INET) {
			continue;
		}
		if (getnameinfo(current->ai_addr, current->ai_addrlen, ipAddress, sizeof(ipAddress),
						NULL, 0, NI_NUMERICHOST) != 0) {
			continue;
		}
		[addresses addObject:[NSString stringWithUTF8String:ipAddress]];
	}
	freeaddrinfo(result);
	return addresses;
#endif
}

+ (NSString *)hostnameForAddress:(NSString *)address {
	NSArray *hostnames = [BDHost hostnamesForAddress:address];
	if ([hostnames count] > 0)
		return [hostnames objectAtIndex:0];
	else
		return nil;
}

+ (NSArray *)hostnamesForAddress:(NSString *)address {
	// Get the host reference for the given address.
	struct addrinfo hints;
	struct addrinfo *result = NULL;
	memset(&hints, 0, sizeof(hints));
	hints.ai_flags    = AI_NUMERICHOST;
	hints.ai_family   = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;
	int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
	if (errorStatus != 0) return nil; // Early return if getaddrinfo fails

#if __APPLE__
	CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, (CFIndex)result->ai_addrlen);
	freeaddrinfo(result); // Free the result immediately after use
	if (addressRef == nil) return nil; // Early return if addressRef creation fails

	CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
	CFRelease(addressRef); // Release addressRef immediately after use
	if (hostRef == nil) return nil; // Early return if hostRef creation fails

	Boolean isSuccess = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
	if (!isSuccess) {
		CFRelease(hostRef); // Release hostRef before returning nil
		return nil;
	}

	// Get the hostnames for the host reference.
	NSArray *hostnamesRef = CFBridgingRelease(CFHostGetNames(hostRef, NULL));
	NSMutableArray *hostnames = [NSMutableArray array];
	for (NSUInteger currentIndex = 0; currentIndex < hostnamesRef.count; currentIndex++) {
		id obj = hostnamesRef[currentIndex];
		[hostnames addObject:obj];
	}

	CFRelease(hostRef); // Release hostRef before returning the hostnames
	return hostnames;
#else
	// getnameinfo is the reverse lookup CFHost performs for kCFHostNames;
	// NI_NAMEREQD keeps the answer a name rather than the numeric fallback.
	char hostname[NI_MAXHOST];
	int nameStatus = getnameinfo(result->ai_addr, result->ai_addrlen, hostname, sizeof(hostname),
								 NULL, 0, NI_NAMEREQD);
	freeaddrinfo(result);
	if (nameStatus != 0) return nil;
	return @[[NSString stringWithUTF8String:hostname]];
#endif
}

+ (NSArray *)ipAddresses {
	NSMutableArray *addresses = [NSMutableArray array];
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *currentAddress = NULL;
	
	int success = getifaddrs(&interfaces);
	if (success == 0) {
		currentAddress = interfaces;
		while(currentAddress != NULL) {
			if(currentAddress->ifa_addr != NULL && currentAddress->ifa_addr->sa_family == AF_INET) {
				NSString *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)currentAddress->ifa_addr)->sin_addr)];
				if (![address isEqual:@"127.0.0.1"]) {
					//NSLog(@"%@ ip: %@", [NSString stringWithUTF8String:currentAddress->ifa_name], address);
					[addresses addObject:address];
				}
			}
			currentAddress = currentAddress->ifa_next;
		}
	}
	freeifaddrs(interfaces);
	return addresses;
}

+ (NSArray *)ethernetAddresses {
	NSMutableArray *addresses = [NSMutableArray array];
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *currentAddress = NULL;
	int success = getifaddrs(&interfaces);
	if (success == 0) {
		currentAddress = interfaces;
		while(currentAddress != NULL) {
#if __APPLE__
			if(currentAddress->ifa_addr->sa_family == AF_LINK) {
				NSString *address = [NSString stringWithUTF8String:ether_ntoa((const struct ether_addr *)LLADDR((struct sockaddr_dl *)currentAddress->ifa_addr))];

				// ether_ntoa doesn't format the ethernet address with padding.
				char paddedAddress[80];
				int a,b,c,d,e,f;
				sscanf([address UTF8String], "%x:%x:%x:%x:%x:%x", &a, &b, &c, &d, &e, &f);
				sprintf(paddedAddress, "%02X:%02X:%02X:%02X:%02X:%02X",a,b,c,d,e,f);
				address = [NSString stringWithUTF8String:paddedAddress];

				if (![address isEqualToString:@"00:00:00:00:00:00"] && ![address isEqualToString:@"00:00:00:00:00:FF"]) {
					//NSLog(@"%@ mac: %@", [NSString stringWithUTF8String:currentAddress->ifa_name], address);
					[addresses addObject:address];
				}
			}
#else
			// Linux spells a link-layer address AF_PACKET/sockaddr_ll and has no
			// LLADDR; the bytes are already padded by sll_halen.
			if(currentAddress->ifa_addr != NULL &&
			   currentAddress->ifa_addr->sa_family == AF_PACKET) {
				struct sockaddr_ll *linkAddress = (struct sockaddr_ll *)currentAddress->ifa_addr;
				if (linkAddress->sll_halen == 6) {
					char paddedAddress[80];
					sprintf(paddedAddress, "%02X:%02X:%02X:%02X:%02X:%02X",
						linkAddress->sll_addr[0], linkAddress->sll_addr[1], linkAddress->sll_addr[2],
						linkAddress->sll_addr[3], linkAddress->sll_addr[4], linkAddress->sll_addr[5]);
					NSString *address = [NSString stringWithUTF8String:paddedAddress];
					if (![address isEqualToString:@"00:00:00:00:00:00"] && ![address isEqualToString:@"00:00:00:00:00:FF"]) {
						[addresses addObject:address];
					}
				}
			}
#endif
			currentAddress = currentAddress->ifa_next;
		}
	}
	freeifaddrs(interfaces);
	return addresses;
}

@end
