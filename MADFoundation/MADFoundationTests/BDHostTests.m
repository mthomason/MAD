//
//  BDHostTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for BDHost: the CFHost-based DNS lookups the connection setup uses to
//  resolve a server name.  Only the IPv4 half is pinned -- that is what the code
//  returns (it filters everything that is not AF_INET) and what the drivers consume.
//
//  +ipAddresses and +ethernetAddresses are implemented but declared in no header and
//  called from nowhere in the tree; they are left uncalled here, because both walk
//  getifaddrs() without checking ifa_addr for NULL and a simulator interface without
//  an address would take the test process down rather than fail a test.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/BDHost.h>

@interface BDHostTests : XCTestCase
@end

@implementation BDHostTests

#pragma mark - Resolution

- (void)testLocalhostResolvesToLoopback {
	NSString *address = [BDHost addressForHostname:@"localhost"];

	XCTAssertEqualObjects(address, @"127.0.0.1");
}

- (void)testLocalhostAddressesContainOnlyIPv4 {
	NSArray *addresses = [BDHost addressesForHostname:@"localhost"];

	XCTAssertNotNil(addresses);
	XCTAssertGreaterThan(addresses.count, (NSUInteger)0);
	XCTAssertTrue([addresses containsObject:@"127.0.0.1"]);
	for (NSString *address in addresses) {
		// IPv6 answers are filtered out, so no address carries a colon.
		XCTAssertFalse([address containsString:@":"], @"unexpected IPv6 address %@", address);
	}
}

- (void)testUnresolvableHostnameReturnsNil {
	// ".invalid" is reserved by RFC 2606 and never resolves.
	NSArray *addresses = [BDHost addressesForHostname:@"mad-designer-tests.invalid"];

	XCTAssertNil(addresses);
	XCTAssertNil([BDHost addressForHostname:@"mad-designer-tests.invalid"]);
}

@end
