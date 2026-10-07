//
//  MADOperationKeyChainDeletePasswordTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADOperationKeyChainDeletePassword.  The key used in the run
//  is a fresh UUID under a UUID description, so neither the u:<key> nor the
//  p:<key> item exists; MADKeyChain's delete reads first and calls
//  SecItemDelete only for a match it found, so the run does not mutate the
//  keychain.  (MADFoundationTests' MADKeyChainTests avoids all keychain I/O for
//  entitlement/flakiness reasons; nothing here writes either.)
//

#import <XCTest/XCTest.h>

#import "MADOperationKeyChainDeletePassword.h"

@interface MADOperationKeyChainDeletePasswordTests : XCTestCase
@end

@implementation MADOperationKeyChainDeletePasswordTests

- (void)testInitCopiesTheKey {
	NSMutableString *key = [NSMutableString stringWithString:@"mad-test-key"];

	MADOperationKeyChainDeletePassword *operation;
	operation = [[MADOperationKeyChainDeletePassword alloc] initWithKey:key];
	[key appendString:@"-mutated"];

	XCTAssertNotNil(operation);
	XCTAssertEqualObjects(operation.key, @"mad-test-key");
	XCTAssertFalse(operation.success);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testCancelledExecuteFinishesWithoutTouchingTheKeyChain {
	MADOperationKeyChainDeletePassword *operation;
	operation = [[MADOperationKeyChainDeletePassword alloc] initWithKey:NSUUID.UUID.UUIDString];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertFalse(operation.success);
}

- (void)testExecuteWithAMissingKeyFinishesWithoutError {
	NSString *key = NSUUID.UUID.UUIDString;
	MADOperationKeyChainDeletePassword *operation;
	operation = [[MADOperationKeyChainDeletePassword alloc] initWithKey:key];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);

	// QUIRK: -execute never assigns self.success, so even a delete that
	// MADKeyChain reports as clean leaves success == NO.  The property is
	// documented as the delete's result and always reads as failure.
	XCTAssertFalse(operation.success);
}

@end
