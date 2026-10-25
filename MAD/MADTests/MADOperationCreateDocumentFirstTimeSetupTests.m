//
//  MADOperationCreateDocumentFirstTimeSetupTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationCreateDocumentFirstTimeSetup: the initializer, the
//  dependency scan, and the run that creates the document tree in the store
//  (RptqDocument plus its sections) and records the change on the document.
//
//  NOT covered, and why:
//    * -execute with no MADOperationCreateDocumentProtocol dependency reaches
//      `[RptqDocument newDocumentForManagedObjectContext:nil]`, which trips its
//      `NSAssert(context != nil)` -- a test would crash rather than assert.  The
//      app's chain always supplies the dependency, so the missing-dependency
//      path is left alone.
//

#import <XCTest/XCTest.h>

#import "MADOperationCreateDocumentFirstTimeSetup.h"
#import "MADOperationCreateDocumentCreateDocument.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

// Declared in the .m only.
@interface MADOperationCreateDocumentFirstTimeSetup (TestWiring)
	- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection;
	- (BOOL)success;
	- (MADDatabaseConnection *)databaseConnection;
@end

@interface MADFirstTimeSetupTestDependency : NSOperation <MADOperationCreateDocumentProtocol>
@end

@interface MADFirstTimeSetupTestDependency ()
@property (nonatomic, strong) MADocument *document;
@end

@implementation MADFirstTimeSetupTestDependency
@end

@interface MADOperationCreateDocumentFirstTimeSetupTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationCreateDocumentFirstTimeSetupTests

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

#pragma mark - Initialization

- (void)testInitDefaults {
	MADOperationCreateDocumentFirstTimeSetup *operation;
	operation = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertFalse(operation.success);
	XCTAssertNil(operation.databaseConnection);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testInitCopiesTheDatabaseConnection {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];

	MADOperationCreateDocumentFirstTimeSetup *operation;
	operation = [[MADOperationCreateDocumentFirstTimeSetup alloc] initWithDatabaseConnection:connection];

	XCTAssertNotNil(operation.databaseConnection);
	// The property is declared copy, so the operation must not hold the caller's
	// instance.
	XCTAssertNotEqual(operation.databaseConnection, connection);
}

#pragma mark - Execute

- (void)testCancelledExecuteFinishesWithoutTouchingTheDocument {
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	MADocument *document = [[MADocument alloc] initWithFileURL:
							[directory URLByAppendingPathComponent:
							 [NSString stringWithFormat:@"first-time-%@.mad", directory.lastPathComponent]]];

	MADFirstTimeSetupTestDependency *dependency = [[MADFirstTimeSetupTestDependency alloc] init];
	dependency.document = document;

	MADOperationCreateDocumentFirstTimeSetup *operation;
	operation = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
	[operation addDependency:dependency];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertFalse(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertFalse(document.hasUnsavedChanges);
}

- (void)testExecuteCreatesAndSavesTheDocumentModel {
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	MADocument *document = [[MADocument alloc] initWithFileURL:
							[directory URLByAppendingPathComponent:
							 [NSString stringWithFormat:@"first-time-%@.mad", directory.lastPathComponent]]];

	MADFirstTimeSetupTestDependency *dependency = [[MADFirstTimeSetupTestDependency alloc] init];
	dependency.document = document;

	MADOperationCreateDocumentFirstTimeSetup *operation;
	operation = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	// Quirk (BUGS.md): the private `success` flag is initialised NO and never
	// assigned -- the local that records the outcome is only used for logging.
	XCTAssertFalse(operation.success);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);

	RptqStoreContext *context = document.storeContext;
	XCTAssertEqual([context objectsForEntity:@"RptqDocument"].count, (NSUInteger)1,
				   @"the setup did not create exactly one RptqDocument");
	// -execute records UIDocumentChangeDone so the new document is seen as dirty.
	XCTAssertTrue(document.hasUnsavedChanges);
}

@end
