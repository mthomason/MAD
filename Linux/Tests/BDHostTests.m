//
//  BDHostTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/BDHostTests.m: coverage for BDHost, the
//  hostname resolution the connection setup uses to resolve a server name.
//  Only the IPv4 half is pinned -- that is what the code returns (it filters
//  everything that is not AF_INET) and what the drivers consume.  The Linux
//  branch of -addressesForHostname: is getaddrinfo/getnameinfo under the same
//  IPv4 filter.
//
//  +ipAddresses and +ethernetAddresses are implemented but declared in no
//  header and called from nowhere in the tree; they are left uncalled here,
//  because both walk getifaddrs() without checking ifa_addr for NULL and an
//  interface without an address would take the test process down rather than
//  fail a test.
//

#import "MADTestSupport.h"
#import <MADFoundation/BDHost.h>

#pragma mark - Resolution

static void testLocalhostResolvesToLoopback(void) {
	NSString *address = [BDHost addressForHostname:@"localhost"];

	MAD_PASS_EQUAL(address, @"127.0.0.1", "localhost resolves to the loopback address");
}

static void testLocalhostAddressesContainOnlyIPv4(void) {
	NSArray *addresses = [BDHost addressesForHostname:@"localhost"];

	MAD_PASS(addresses != nil, "addresses is not nil");
	MAD_PASS(addresses.count > (NSUInteger)0, "at least one address");
	MAD_PASS([addresses containsObject:@"127.0.0.1"], "the loopback address is present");
	for (NSString *address in addresses) {
		// IPv6 answers are filtered out, so no address carries a colon.
		MAD_PASS(![address containsString:@":"], "no IPv6 address: %s", [address UTF8String]);
	}
}

static void testUnresolvableHostnameReturnsNil(void) {
	// ".invalid" is reserved by RFC 2606 and never resolves.
	NSArray *addresses = [BDHost addressesForHostname:@"mad-designer-tests.invalid"];

	MAD_PASS(addresses == nil, "no address list for an unresolvable name");
	MAD_PASS([BDHost addressForHostname:@"mad-designer-tests.invalid"] == nil, "no address for an unresolvable name");
}

MAD_TEST_MAIN("BDHostTests",
	MAD_TEST(testLocalhostResolvesToLoopback),
	MAD_TEST(testLocalhostAddressesContainOnlyIPv4),
	MAD_TEST(testUnresolvableHostnameReturnsNil));
