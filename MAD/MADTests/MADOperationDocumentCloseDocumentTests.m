//
//  MADOperationDocumentCloseDocumentTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationDocumentCloseDocument: the dependency scan, the
//  quick finish for a document that was never opened (Closed state, no store),
//  and the real close of an open document through MADocument +close:completion:.
//
//  The operation's failure branch (MADocument answering NO to the close, error
//  893) has no reachable trigger in a logic test: the document's own
//  closeWithCompletionHandler: reports failure only if the store save fails,
//  and the fixture's store is healthy.
//

#import <XCTest/XCTest.h>

#import "MADOperationDocumentCloseDocument.h"
#import "MADOperationCreateDocumentCreateDocument.h"

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

@interface MADCloseDocumentTestDependency : NSOperation <MADOperationCreateDocumentProtocol>
@end

@interface MADCloseDocumentTestDependency ()
@property (nonatomic, strong) MADocument *document;
@end

@implementation MADCloseDocumentTestDependency
@end

@interface MADOperationDocumentCloseDocumentTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationDocumentCloseDocumentTests

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

- (void)waitForOperation:(NSOperation *)operation {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20.0];
	while (!operation.isFinished && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
}

#pragma mark - Execute

- (void)testExecuteWithoutDependencyFinishes {
	// With no MADOperationCreateDocumentProtocol dependency the document is nil;
	// +[MADocument close:completion:] treats a nil document as an already-closed
	// one and reports success, so the missing dependency finishes cleanly.
	MADOperationDocumentCloseDocument *operation = [[MADOperationDocumentCloseDocument alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testExecuteWithADocumentThatWasNeverOpenedFinishes {
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	MADocument *document = [[MADocument alloc] initWithFileURL:
							 [directory URLByAppendingPathComponent:
							  [NSString stringWithFormat:@"closed-%@.mad", directory.lastPathComponent]]];
	XCTAssertEqual(document.documentState, UIDocumentStateClosed);

	MADCloseDocumentTestDependency *dependency = [[MADCloseDocumentTestDependency alloc] init];
	dependency.document = document;

	MADOperationDocumentCloseDocument *operation = [[MADOperationDocumentCloseDocument alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertEqual(document.documentState, UIDocumentStateClosed);
}

- (void)testCancelledExecuteFinishesWithoutClosing {
	NSURL *directory = [self newTemporaryDirectory];
	MADocument *document = [[MADocument alloc] initWithFileURL:
							 [directory URLByAppendingPathComponent:
							  [NSString stringWithFormat:@"cancelled-%@.mad", directory.lastPathComponent]]];

	MADCloseDocumentTestDependency *dependency = [[MADCloseDocumentTestDependency alloc] init];
	dependency.document = document;

	MADOperationDocumentCloseDocument *operation = [[MADOperationDocumentCloseDocument alloc] init];
	[operation addDependency:dependency];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertEqual(document.documentState, UIDocumentStateClosed);
}

- (void)testExecuteClosesAnOpenDocument {
	NSURL *directory = [self newTemporaryDirectory];
	NSURL *documentURL = [directory URLByAppendingPathComponent:
						  [NSString stringWithFormat:@"open-%@.mad", directory.lastPathComponent]];

	// Fixture: write a document through the document's own save path, the way
	// MADDocumentTests does, so the open below finds a real .mad.
	MADocument *writer = [[MADocument alloc] initWithFileURL:documentURL];
	RptqStoreContext *context = writer.storeContext;
	XCTAssertNotNil(context);
	XCTAssertNotNil([context insertObjectForEntity:@"RptqDocument" identifier:1]);
	XCTAssertTrue([context save:NULL]);
	NSError *error = nil;
	XCTAssertTrue([writer writeContents:nil
						  andAttributes:nil
							safelyToURL:documentURL
					   forSaveOperation:UIDocumentSaveForCreating
								  error:&error],
				  @"the fixture document did not save: %@", error);

	// Open it the way the app does.
	MADocument *document = [[MADocument alloc] initWithFileURL:documentURL];
	XCTestExpectation *opened = [self expectationWithDescription:@"open"];
	[document openWithCompletionHandler:^(BOOL success) {
		XCTAssertTrue(success, @"opening the fixture document failed");
		[opened fulfill];
	}];
	[self waitForExpectations:@[ opened ] timeout:20];
	XCTAssertEqual(document.documentState, UIDocumentStateNormal);
	XCTAssertNotNil(document.storeContext);

	MADCloseDocumentTestDependency *dependency = [[MADCloseDocumentTestDependency alloc] init];
	dependency.document = document;

	MADOperationDocumentCloseDocument *operation = [[MADOperationDocumentCloseDocument alloc] init];
	[operation addDependency:dependency];

	[operation execute];
	[self waitForOperation:operation];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertEqual(document.documentState, UIDocumentStateClosed,
				   @"the operation did not close the open document");
}

@end
