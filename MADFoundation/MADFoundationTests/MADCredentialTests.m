//
//  MADCredentialTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADCredential: the username/password value object used to carry
//  database credentials into connection flows.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADCredential.h>

@interface MADCredentialTests : XCTestCase
@end

@implementation MADCredentialTests

- (void)testInitWithUsernameAndPassword {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];
	XCTAssertEqualObjects(credential.username, @"alice");
	XCTAssertEqualObjects(credential.password, @"secret");
}

- (void)testInitWithNilValues {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:nil andPassword:nil];
	XCTAssertNil(credential.username);
	XCTAssertNil(credential.password);
}

- (void)testCopy {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];
	MADCredential *copy = [credential copy];
	XCTAssertNotNil(copy);
	XCTAssertTrue(copy != credential);
	XCTAssertEqualObjects(copy.username, @"alice");
	XCTAssertEqualObjects(copy.password, @"secret");
}

- (void)testSupportsSecureCoding {
	XCTAssertTrue([MADCredential supportsSecureCoding]);
}

- (void)testSecureCodingRoundTrip {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADCredential *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADCredential class] fromData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqualObjects(decoded.username, @"alice");
	XCTAssertEqualObjects(decoded.password, @"secret");
}

@end
