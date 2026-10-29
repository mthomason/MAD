//
//  MADOperationCreateDocumentAddConnectionTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationCreateDocumentAddConnection: the initializer's copy
//  of the connection, the dependency scan that finds the MADocument, and the
//  active-document-model side effect of -execute.
//
//  NOTE: -execute messages the dependency's document and sets success = YES no
//  matter what it finds, so there is no error path to pin: with no document
//  dependency at all the operation still reports success (see the quirk test).
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <XCTest/XCTest.h>

#import "MADOperationCreateDocumentAddConnection.h"
#import "MADOperationCreateDocumentCreateDocument.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

// The class extension that owns these is in the .m; declared here as the bridge
// the tests read through.
@interface MADOperationCreateDocumentAddConnection (TestWiring)
	- (BOOL)success;
	- (MADDatabaseConnection *)databaseConnection;
@end

// A dependency that hands the operation a document, which is the only thing
// -execute reads from its dependencies.
@interface MADAddConnectionTestDependency : NSOperation <MADOperationCreateDocumentProtocol>
@end

@interface MADAddConnectionTestDependency ()
@property (nonatomic, strong) MADocument *document;
@end

@implementation MADAddConnectionTestDependency
@end

@interface MADOperationCreateDocumentAddConnectionTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationCreateDocumentAddConnectionTests

#pragma mark - Helpers

- (void)tearDown {
	for (NSURL *directory in self.temporaryDirectories) {
		[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
	}
	self.temporaryDirectories = nil;
	[super tearDown];
}

- (NSURL *)newTemporaryDirectory {
	NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
						URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	if (self.temporaryDirectories == nil) {
		self.temporaryDirectories = [NSMutableArray array];
	}
	[self.temporaryDirectories addObject:directory];
	return directory;
}

// A document whose store is open and holds the RptqDocument row that
// -activeDocumentModel reads back.
- (MADocument *)newDocumentWithModelInDirectory:(NSURL *)directory {
	// The document's guts -- and the store inside them -- are keyed by document
	// name in the host's shared tmp, so a fixed name opens whatever a previous
	// run left behind.  The fixture directory is unique per test; carry that
	// into the name so each run gets a fresh store.
	NSURL *url = [directory URLByAppendingPathComponent:
				  [NSString stringWithFormat:@"add-connection-%@.mad", directory.lastPathComponent]];
	MADocument *document = [[MADocument alloc] initWithFileURL:url];

	RptqStoreContext *context = document.storeContext;
	XCTAssertNotNil(context, @"the fixture document's store did not open");
	XCTAssertNotNil([context insertObjectForEntity:@"RptqDocument" identifier:1]);
	XCTAssertTrue([context save:NULL]);

	return document;
}

#pragma mark - Initialization

- (void)testInitDefaults {
	MADOperationCreateDocumentAddConnection *operation;
	operation = [[MADOperationCreateDocumentAddConnection alloc] init];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertFalse(operation.success);
	XCTAssertNil(operation.databaseConnection);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testInitCopiesTheDatabaseConnection {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];

	MADOperationCreateDocumentAddConnection *operation;
	operation = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:connection];

	XCTAssertNotNil(operation.databaseConnection);
	// The property is declared copy, so the operation must not hold the caller's
	// instance.
	XCTAssertNotEqual(operation.databaseConnection, connection);
	XCTAssertFalse(operation.success);
}

#pragma mark - Execute

- (void)testExecuteWithoutADocumentDependencyStillReportsSuccess {
	// QUIRK: the scan leaves document nil, `[document activeDocumentModel]` is a
	// message to nil, and -execute still sets success = YES and finishes with no
	// error.  Nothing distinguishes "added the connection" from "found no
	// document".
	MADOperationCreateDocumentAddConnection *operation;
	operation = [[MADOperationCreateDocumentAddConnection alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertTrue(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testExecuteWithDocumentDependencyBuildsTheActiveDocumentModel {
	NSURL *directory = [self newTemporaryDirectory];
	MADocument *document = [self newDocumentWithModelInDirectory:directory];

	MADAddConnectionTestDependency *dependency = [[MADAddConnectionTestDependency alloc] init];
	dependency.document = document;

	MADOperationCreateDocumentAddConnection *operation;
	operation = [[MADOperationCreateDocumentAddConnection alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertTrue(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertNotNil(document.activeDocumentModel, @"-execute did not build the active document model");
}

- (void)testCancelledExecuteFinishesWithoutTouchingTheDocument {
	MADOperationCreateDocumentAddConnection *operation;
	operation = [[MADOperationCreateDocumentAddConnection alloc] init];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertFalse(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

@end
#endif
