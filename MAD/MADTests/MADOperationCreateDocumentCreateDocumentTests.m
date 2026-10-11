//
//  MADOperationCreateDocumentCreateDocumentTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADOperationCreateDocumentCreateDocument: the connection copy,
//  the credentials pull from a MADOperationHoldsCredentialsProtocol dependency,
//  the URL scan over the unique-URL dependency, and the create-and-save run
//  against a temporary directory.  The save path is MADocument's own (the store
//  is written and archived), so it needs no database server.
//
//  NOT covered, and why:
//    * -execute with neither a _url nor a unique-URL dependency hands nil to
//      MADocument/UIDocument; UIDocument's behaviour for a nil URL is not this
//      framework's contract, so it is left unexercised.
//

#import <XCTest/XCTest.h>

#import "MADOperationCreateDocumentCreateDocument.h"
#import "MADOperationHoldsCredentialsProtocol.h"
#import "MADOperationUniqueUrlForFilename.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADocument.h>

// Methods the class implements but declares in no header: the hidden file-URL
// initializer, the delegate credentials hook, and the connection property.
@interface MADOperationCreateDocumentCreateDocument (TestHiddenAPI)
	- (instancetype)initWithFileUrl:(NSURL *)url;
	- (MADCredential *)getCredentialsForKey:(NSString *)key;
	- (MADDatabaseConnection *)databaseConnection;
@end

// A credential holder the operation can pull from.
@interface MADCreateDocumentTestCredentials : NSOperation <MADOperationHoldsCredentialsProtocol>
@end

@interface MADCreateDocumentTestCredentials ()
@property (nonatomic, strong) MADCredential *credentials;
@property (nonatomic, assign) BOOL gotCredentials;
@property (nonatomic, assign) BOOL manuallyInputtedCredentials;
@end

@implementation MADCreateDocumentTestCredentials
@end

@interface MADOperationCreateDocumentCreateDocumentTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationCreateDocumentCreateDocumentTests

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

- (void)testConformsToTheCreateDocumentProtocol {
	XCTAssertTrue([MADOperationCreateDocumentCreateDocument conformsToProtocol:
				   @protocol(MADOperationCreateDocumentProtocol)]);
}

- (void)testInitDefaults {
	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:nil];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertNil(operation.document);
	XCTAssertNil(operation.databaseConnection);
	XCTAssertNil([operation getCredentialsForKey:@"anything"]);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testInitCopiesTheDatabaseConnection {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:connection];

	XCTAssertNotNil(operation.databaseConnection);
	// The property is declared copy, so the operation must not hold the caller's
	// instance.
	XCTAssertNotEqual(operation.databaseConnection, connection);
}

#pragma mark - Credentials

- (void)testGetCredentialsPullsFromAHoldingDependency {
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"user" andPassword:@"pass"];
	MADCreateDocumentTestCredentials *holder = [[MADCreateDocumentTestCredentials alloc] init];
	holder.credentials = credential;
	holder.gotCredentials = YES;

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:nil];
	[operation addDependency:holder];

	MADCredential *result = [operation getCredentialsForKey:@"anything"];

	XCTAssertNotNil(result);
	XCTAssertEqualObjects(result.username, @"user");
	XCTAssertEqualObjects(result.password, @"pass");
	// The credentials property is declared copy.
	XCTAssertNotEqual(result, credential);
}

- (void)testGetCredentialsIgnoresAHolderThatHasNotGotThem {
	MADCreateDocumentTestCredentials *holder = [[MADCreateDocumentTestCredentials alloc] init];
	holder.credentials = [[MADCredential alloc] initWithUsername:@"user" andPassword:@"pass"];
	holder.gotCredentials = NO;

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:nil];
	[operation addDependency:holder];

	XCTAssertNil([operation getCredentialsForKey:@"anything"]);
}

- (void)testGetCredentialsReturnsNilWithoutDependencies {
	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:nil];

	XCTAssertNil([operation getCredentialsForKey:@"anything"]);
}

#pragma mark - Execute

- (void)testExecuteWithFileUrlCreatesAndSavesTheDocument {
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	NSURL *url = [directory URLByAppendingPathComponent:
				  [NSString stringWithFormat:@"created-%@.mad", directory.lastPathComponent]];

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithFileUrl:url];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);

	MADocument *document = operation.document;
	XCTAssertNotNil(document);
	XCTAssertEqualObjects(document.fileURL.lastPathComponent, url.lastPathComponent);
	// -execute clears autosave and takes over as the document's delegate.
	XCTAssertFalse(document.isAutosaveEnabled);
	XCTAssertTrue((id)document.documentDelegate == (id)operation);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:url.path],
				  @"the document archive was not written");
}

- (void)testExecuteUsesTheUniqueUrlDependency {
	NSURL *directory = [self newTemporaryDirectory];
	MADOperationUniqueUrlForFilename *urlOperation;
	urlOperation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"FromDependency"
																	   pathExtension:@"mad"
																andDocumentsDirectory:directory];
	[urlOperation execute];
	XCTAssertNotNil(urlOperation.uniqueUrl);

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:nil];
	[operation addDependency:urlOperation];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertNotNil(operation.document);
	XCTAssertEqualObjects(operation.document.fileURL.lastPathComponent,
						  urlOperation.uniqueUrl.lastPathComponent);
}

- (void)testExecuteCancelledFinishesWithoutCreatingTheDocument {
	NSURL *directory = [self newTemporaryDirectory];
	NSURL *url = [directory URLByAppendingPathComponent:
				  [NSString stringWithFormat:@"cancelled-%@.mad", directory.lastPathComponent]];

	MADOperationCreateDocumentCreateDocument *operation;
	operation = [[MADOperationCreateDocumentCreateDocument alloc] initWithFileUrl:url];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertNil(operation.document);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:url.path]);
}

// A save-failure test (error 347 on this class) was written and removed: pointing
// the create at a path that cannot host the store (e.g. /dev/null/created.mad) drives
// UIDocument's archiver into a runaway error loop -- the log fills with
// archive_write_data() returned -30 -- and the test process hangs rather than failing
// the save.  The 347 contract is pinned by
// MADOperationCreateDocumentSaveAndCloseNewDocumentTests, whose failure path does not
// touch UIDocument's archive machinery.

@end
