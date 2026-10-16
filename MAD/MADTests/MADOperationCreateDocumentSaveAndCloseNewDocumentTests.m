//
//  MADOperationCreateDocumentSaveAndCloseNewDocumentTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADOperationCreateDocumentSaveAndCloseNewDocument: the
//  dependency scan, the missing-document error (domain is the class name, code
//  347), and the close of a document that was never opened.  Closing an *open*
//  document goes through UIDocument's file machinery and is covered for the
//  plain close operation in MADOperationDocumentCloseDocumentTests.m.
//

#import <XCTest/XCTest.h>

#import "MADOperationCreateDocumentSaveAndCloseNewDocument.h"
#import "MADOperationCreateDocumentCreateDocument.h"

#import <MAD/MADocument.h>

@interface MADSaveAndCloseTestDependency : NSOperation <MADOperationCreateDocumentProtocol>
@end

@interface MADSaveAndCloseTestDependency ()
@property (nonatomic, strong) MADocument *document;
@end

@implementation MADSaveAndCloseTestDependency
@end

@interface MADOperationCreateDocumentSaveAndCloseNewDocumentTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationCreateDocumentSaveAndCloseNewDocumentTests

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

#pragma mark - Execute

- (void)testExecuteWithoutDependencyFinishesWithError347 {
	MADOperationCreateDocumentSaveAndCloseNewDocument *operation;
	operation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	NSError *error = operation.errors.firstObject;
	XCTAssertEqualObjects(error.domain, @"MADOperationCreateDocumentSaveAndCloseNewDocument");
	XCTAssertEqual(error.code, 347);
	XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey],
						  @"Document object not found for save and close.");
}

- (void)testExecuteWithADependencyWhoseDocumentIsNilFinishesWithError347 {
	MADSaveAndCloseTestDependency *dependency = [[MADSaveAndCloseTestDependency alloc] init];

	MADOperationCreateDocumentSaveAndCloseNewDocument *operation;
	operation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	XCTAssertEqualObjects(operation.errors.firstObject.domain,
						  @"MADOperationCreateDocumentSaveAndCloseNewDocument");
	XCTAssertEqual(operation.errors.firstObject.code, 347);
}

- (void)testExecuteWithDocumentDependencyClosesAndFinishes {
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	MADocument *document = [[MADocument alloc] initWithFileURL:
							[directory URLByAppendingPathComponent:
							 [NSString stringWithFormat:@"save-and-close-%@.mad", directory.lastPathComponent]]];
	XCTAssertEqual(document.documentState, UIDocumentStateClosed);

	MADSaveAndCloseTestDependency *dependency = [[MADSaveAndCloseTestDependency alloc] init];
	dependency.document = document;

	MADOperationCreateDocumentSaveAndCloseNewDocument *operation;
	operation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	// The document was never opened, so -closeWithCompletionHandler: reports the
	// close directly and the state stays Closed.
	XCTAssertEqual(document.documentState, UIDocumentStateClosed);
}

- (void)testCancelledExecuteFinishesWithoutError {
	MADSaveAndCloseTestDependency *dependency = [[MADSaveAndCloseTestDependency alloc] init];

	MADOperationCreateDocumentSaveAndCloseNewDocument *operation;
	operation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
	[operation addDependency:dependency];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

@end
