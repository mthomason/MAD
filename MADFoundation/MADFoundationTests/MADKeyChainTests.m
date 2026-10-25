//
//  MADKeyChainTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the deterministic parts of MADKeyChain: the key derivation and
//  the SecItem query dictionaries.  (Actual keychain I/O is left out of the
//  logic-test suite to avoid entitlement/timing flakiness.)
//

#import <XCTest/XCTest.h>

#import <Security/Security.h>
#import <MADFoundation/MADKeyChain.h>

@interface MADKeyChainTests : XCTestCase
@end

@implementation MADKeyChainTests

- (void)testAccountDescriptionConstants {
	XCTAssertEqualObjects(MADKeyChainUsernameAccountDesc, @"Client Database Username");
	XCTAssertEqualObjects(MADKeyChainPasswordAccountDesc, @"Client Database Password");
}

- (void)testUsernameKeyDerivation {
	XCTAssertEqualObjects([MADKeyChain newKeyForUsernameWithMainKey:@"db"], @"u:db");
	XCTAssertEqualObjects([MADKeyChain newKeyForUsernameWithMainKey:@""], @"u:");
}

- (void)testPasswordKeyDerivation {
	XCTAssertEqualObjects([MADKeyChain newKeyForPasswordWithMainKey:@"db"], @"p:db");
	XCTAssertEqualObjects([MADKeyChain newKeyForPasswordWithMainKey:@""], @"p:");
}

- (void)testQueryUsernameDefinition {
	NSDictionary *query = [MADKeyChain queryUsernameDefination:@"db"];
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecClass], (__bridge NSString *)kSecClassGenericPassword);
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrService], @"u:db");
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrAccount], MADKeyChainUsernameAccountDesc);
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecReturnData], @YES);
}

- (void)testQueryPasswordDefinition {
	NSDictionary *query = [MADKeyChain queryPasswordDefination:@"db"];
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecClass], (__bridge NSString *)kSecClassGenericPassword);
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrService], @"p:db");
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrAccount], MADKeyChainPasswordAccountDesc);
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecReturnData], @YES);
}

- (void)testQueryDefinition {
	NSDictionary *query = [MADKeyChain queryDefination:@"svc" withDescription:@"desc"];
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecClass], (__bridge NSString *)kSecClassGenericPassword);
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrService], @"svc");
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecAttrAccount], @"desc");
	XCTAssertEqualObjects(query[(__bridge NSString *)kSecReturnData], @YES);
}

@end
