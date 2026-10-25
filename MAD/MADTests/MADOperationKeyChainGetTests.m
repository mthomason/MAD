//
//  MADOperationKeyChainGetTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationKeyChainGet: the initializer wiring, the result
//  protocol it adopts, and the error finish for a key that is not in the
//  keychain.  The key is a fresh UUID under a fresh UUID description, so the
//  SecItemCopyMatching is a read that must miss; nothing writes the keychain.
//

#import <XCTest/XCTest.h>

#import "MADOperationKeyChainGet.h"

#import <MADFoundation/MADOperationResultStringProtocol.h>

// Declared in the .m only.
@interface MADOperationKeyChainGet (TestWiring)
	- (NSString *)keyDescription;
@end

@interface MADOperationKeyChainGetTests : XCTestCase
@end

@implementation MADOperationKeyChainGetTests

#pragma mark - Initialization

- (void)testInitWiring {
	MADOperationKeyChainGet *operation;
	operation = [[MADOperationKeyChainGet alloc] initWithKey:@"service" withDescription:@"description"];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertEqualObjects(operation.key, @"service");
	XCTAssertEqualObjects([operation keyDescription], @"description");
	XCTAssertNil(operation.value);
	XCTAssertFalse(operation.success);
	// The read operation type is a plain assign with no initializer, so it reads
	// as the first enum case.
	XCTAssertEqual(operation.readOperationType, MADKeyChainReadOperationTypeUsername);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testConformsToTheResultStringProtocol {
	MADOperationKeyChainGet *operation;
	operation = [[MADOperationKeyChainGet alloc] initWithKey:@"service" withDescription:@"description"];

	XCTAssertTrue([MADOperationKeyChainGet conformsToProtocol:
				   @protocol(MADOperationResultStringProtocol)]);
	XCTAssertTrue([operation respondsToSelector:@selector(key)]);
	XCTAssertTrue([operation respondsToSelector:@selector(value)]);
	XCTAssertTrue([operation respondsToSelector:@selector(success)]);
	XCTAssertTrue([operation respondsToSelector:@selector(readOperationType)]);
}

- (void)testReadOperationTypeIsSettable {
	MADOperationKeyChainGet *operation;
	operation = [[MADOperationKeyChainGet alloc] initWithKey:@"service" withDescription:@"description"];

	operation.readOperationType = MADKeyChainReadOperationTypePassword;

	XCTAssertEqual(operation.readOperationType, MADKeyChainReadOperationTypePassword);
}

#pragma mark - Execute

- (void)testExecuteForAMissingKeyFinishesWithAnError {
	NSString *key = NSUUID.UUID.UUIDString;
	NSString *description = NSUUID.UUID.UUIDString;
	MADOperationKeyChainGet *operation;
	operation = [[MADOperationKeyChainGet alloc] initWithKey:key withDescription:description];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertNil(operation.value);
	XCTAssertFalse(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	NSError *error = operation.errors.firstObject;
	XCTAssertEqualObjects(error.domain, @"MADOperationKeyChainGet");
	// The status is errSecItemNotFound when the keychain is reachable and
	// errSecMissingEntitlement when it is not; all this pins is that a miss is
	// reported as a non-zero status rather than success.
	XCTAssertNotEqual(error.code, 0);
}

- (void)testCancelledExecuteFinishesWithoutReadingTheKeyChain {
	MADOperationKeyChainGet *operation;
	operation = [[MADOperationKeyChainGet alloc] initWithKey:NSUUID.UUID.UUIDString
											 withDescription:NSUUID.UUID.UUIDString];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertNil(operation.value);
	XCTAssertFalse(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

@end
