//
//  MADOperationKeyChainPutTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADOperationKeyChainPut: the initializer wiring, the dependency
//  scan for the value to write, and the not-found error the operation raises
//  when no dependency has one.
//
//  NOT covered, and why:
//    * A dependency that returns a value would reach MADKeyChain +saveToken:,
//      which writes to the real keychain; there is no seam to intercept the
//      class-method call, so the write path is left unexercised.  (The not-found
//      paths above never touch the keychain.)
//

#import <XCTest/XCTest.h>

#import "MADOperationKeyChainPut.h"
#import "MADKeyChainKeyValueProtocol.h"

// Both properties are declared in the .m only; declared here as the bridge.
@interface MADOperationKeyChainPut (TestWiring)
	- (NSString *)key;
	- (NSString *)keyDescription;
@end

// A dependency that supplies (or does not supply) the value for a key.
@interface MADKeyChainTestOperation : NSOperation <MADKeyChainKeyValueProtocol>
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *values;
@end

@implementation MADKeyChainTestOperation

- (NSString *)valueForKey:(NSString *)key {
	return self.values[key];
}

@end

@interface MADOperationKeyChainPutTests : XCTestCase
@end

@implementation MADOperationKeyChainPutTests

#pragma mark - Initialization

- (void)testInitCopiesTheKeyAndDescription {
	NSMutableString *key = [NSMutableString stringWithString:@"mad-test-key"];
	NSMutableString *description = [NSMutableString stringWithString:@"mad-test-description"];

	MADOperationKeyChainPut *operation;
	operation = [[MADOperationKeyChainPut alloc] initWithKey:key description:description];
	[key appendString:@"-mutated"];
	[description appendString:@"-mutated"];

	XCTAssertNotNil(operation);
	XCTAssertEqualObjects(operation.key, @"mad-test-key");
	XCTAssertEqualObjects([operation keyDescription], @"mad-test-description");
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

#pragma mark - Execute

- (void)testExecuteWithoutDependenciesFinishesWithNotFound {
	MADOperationKeyChainPut *operation;
	operation = [[MADOperationKeyChainPut alloc] initWithKey:@"mad-test-key" description:@"mad-test-description"];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	NSError *error = operation.errors.firstObject;
	XCTAssertEqualObjects(error.domain, @"MADKCP");
	XCTAssertEqual(error.code, 35);
}

- (void)testExecuteWithADependencyWithoutAValueFinishesWithNotFound {
	MADKeyChainTestOperation *dependency = [[MADKeyChainTestOperation alloc] init];

	MADOperationKeyChainPut *operation;
	operation = [[MADOperationKeyChainPut alloc] initWithKey:@"mad-test-key" description:@"mad-test-description"];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	NSError *error = operation.errors.firstObject;
	XCTAssertEqualObjects(error.domain, @"MADKCP");
	XCTAssertEqual(error.code, 35);
}

- (void)testCancelledExecuteFinishesWithoutWriting {
	MADKeyChainTestOperation *dependency = [[MADKeyChainTestOperation alloc] init];
	dependency.values = @{ @"mad-test-key": @"a-value" };

	MADOperationKeyChainPut *operation;
	operation = [[MADOperationKeyChainPut alloc] initWithKey:@"mad-test-key" description:@"mad-test-description"];
	[operation addDependency:dependency];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

@end
