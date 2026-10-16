//
//  MADCredentialTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADCredentialTests.m: coverage for
//  MADCredential, the username/password value object used to carry database
//  credentials into connection flows.
//
//  The original's testSecureCodingRoundTrip used requiringSecureCoding:YES
//  and unarchivedObjectOfClass:fromData:error:.  GNUstep has neither (the
//  strict archive returns nil and neither class-keyed entry point exists --
//  see the Phase B report in MAD_LINUX.md), so the round trip here runs on
//  the permissive/classic path and the strict path is pinned as a need.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADCredential.h>

static void testInitWithUsernameAndPassword(void) {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];
	MAD_PASS_EQUAL(credential.username, @"alice", "username");
	MAD_PASS_EQUAL(credential.password, @"secret", "password");
}

static void testInitWithNilValues(void) {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:nil andPassword:nil];
	MAD_PASS(credential.username == nil, "nil username stays nil");
	MAD_PASS(credential.password == nil, "nil password stays nil");
}

static void testCopy(void) {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];
	MADCredential *copy = [credential copy];
	MAD_PASS(copy != nil, "copy is not nil");
	MAD_PASS(copy != credential, "copy is a distinct object");
	MAD_PASS_EQUAL(copy.username, @"alice", "copy's username");
	MAD_PASS_EQUAL(copy.password, @"secret", "copy's password");
}

static void testSupportsSecureCoding(void) {
	MAD_PASS([MADCredential supportsSecureCoding], "MADCredential declares secure coding support");
}

static void testSecureCodingRoundTrip(void) {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential requiringSecureCoding:NO error:&error];
	MAD_PASS(data != nil, "archive");
	MAD_PASS(error == nil, "no error archiving");

	MADCredential *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	MAD_PASS(decoded != nil, "decoded");
	MAD_PASS([decoded isKindOfClass:[MADCredential class]], "decoded is a MADCredential");
	MAD_PASS_EQUAL(decoded.username, @"alice", "username survives the round trip");
	MAD_PASS_EQUAL(decoded.password, @"secret", "password survives the round trip");
}

static void testStrictSecureCodingIsUnavailable(void) {
	// Not a defect in MAD: GNUstep's archiver has no secure-coding support.
	// Keep this visible so the Phase C work sees it rather than a silent skip.
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"secret"];
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential requiringSecureCoding:YES error:&error];
	MAD_NEED(data != nil, @"requiringSecureCoding:YES returns nil on GNUstep (no secure-coding support)");
}

MAD_TEST_MAIN("MADCredentialTests",
	MAD_TEST(testInitWithUsernameAndPassword),
	MAD_TEST(testInitWithNilValues),
	MAD_TEST(testCopy),
	MAD_TEST(testSupportsSecureCoding),
	MAD_TEST(testSecureCodingRoundTrip),
	MAD_TEST(testStrictSecureCodingIsUnavailable));
