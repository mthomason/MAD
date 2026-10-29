//
//  MADOperationDeleteFileTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationDeleteFile, which only deletes when a dependency
//  that conforms to MADOperationTestResults reports failure, and only knows
//  which file to delete from a MADOperationUniqueUrlForFilenameProtocol or
//  MADOperationCreateDocumentProtocol dependency.
//
//  NOT covered, and why:
//    * A document dependency combined with a failing results dependency is
//      order-dependent: -execute stops at the first
//      MADOperationCreateDocumentProtocol dependency (`break`), so whether the
//      results dependency was seen before it -- and therefore whether the file
//      is deleted at all -- depends on the undefined order of -dependencies.
//      A test cannot pin either outcome; see the comment in the source.  Only
//      the URL path (no document dependency) is driven here.
//    * A failing results dependency with no URL dependency leaves fileURL nil
//      and hands it to NSFileCoordinator; that is not exercised.
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <XCTest/XCTest.h>

#import "MADOperationDeleteFile.h"
#import "MADOperationCreateDocumentCreateDocument.h"
#import "MADOperationUniqueUrlForFilename.h"

#import <MADFoundation/MADOperationTestResults.h>
#import <MAD/MADocument.h>

// The class the operation reads through the test-results protocol.
@interface MADDeleteFileTestResults : NSOperation <MADOperationTestResults>
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign, getter=isSuccess) BOOL success;
@end

@implementation MADDeleteFileTestResults
@end

@interface MADDeleteFileTestDependency : NSOperation <MADOperationCreateDocumentProtocol>
@end

@interface MADDeleteFileTestDependency ()
@property (nonatomic, strong) MADocument *document;
@end

@implementation MADDeleteFileTestDependency
@end

@interface MADOperationDeleteFileTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryDirectories;
@end

@implementation MADOperationDeleteFileTests

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

// The URL operation never hands back a path that exists, so the file is made
// afterwards, the way a failed create leaves its output behind.
- (MADOperationUniqueUrlForFilename *)newUrlOperationInDirectory:(NSURL *)directory named:(NSString *)name {
	MADOperationUniqueUrlForFilename *urlOperation;
	urlOperation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:name
																	   pathExtension:@"mad"
																andDocumentsDirectory:directory];
	[urlOperation execute];
	return urlOperation;
}

- (void)waitForOperation:(NSOperation *)operation {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10.0];
	while (!operation.isFinished && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
}

#pragma mark - Execute

- (void)testExecuteWithoutDependenciesFinishesAndDeletesNothing {
	NSURL *directory = [self newTemporaryDirectory];
	NSURL *fileURL = [directory URLByAppendingPathComponent:@"untouched.mad"];
	[[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:[NSData data] attributes:nil];

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
}

- (void)testExecuteWithFailingResultsDeletesTheFile {
	NSURL *directory = [self newTemporaryDirectory];
	MADOperationUniqueUrlForFilename *urlOperation = [self newUrlOperationInDirectory:directory
																				named:@"delete-me"];
	NSURL *fileURL = urlOperation.uniqueUrl;
	XCTAssertTrue([[NSFileManager defaultManager] createFileAtPath:fileURL.path
														  contents:[NSData data]
													   attributes:nil]);

	MADDeleteFileTestResults *results = [[MADDeleteFileTestResults alloc] init];
	results.success = NO;

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];
	[operation addDependency:urlOperation];
	[operation addDependency:results];

	[operation execute];
	[self waitForOperation:operation];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path],
				   @"the failed create's file was not deleted");
}

- (void)testExecuteWithSuccessfulResultsLeavesTheFile {
	NSURL *directory = [self newTemporaryDirectory];
	MADOperationUniqueUrlForFilename *urlOperation = [self newUrlOperationInDirectory:directory
																				named:@"keep-me"];
	NSURL *fileURL = urlOperation.uniqueUrl;
	XCTAssertTrue([[NSFileManager defaultManager] createFileAtPath:fileURL.path
														  contents:[NSData data]
													   attributes:nil]);

	MADDeleteFileTestResults *results = [[MADDeleteFileTestResults alloc] init];
	results.success = YES;

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];
	[operation addDependency:urlOperation];
	[operation addDependency:results];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path],
				  @"a successful result must not delete the file");
}

- (void)testExecuteWithFailingResultsOnAMissingFileFinishesWithAnError {
	NSURL *directory = [self newTemporaryDirectory];
	MADOperationUniqueUrlForFilename *urlOperation = [self newUrlOperationInDirectory:directory
																				named:@"already-gone"];

	MADDeleteFileTestResults *results = [[MADDeleteFileTestResults alloc] init];
	results.success = NO;

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];
	[operation addDependency:urlOperation];
	[operation addDependency:results];

	[operation execute];
	[self waitForOperation:operation];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)1);
	// The removal error comes back from NSFileManager through
	// MADFileUtilities; its exact code depends on the file coordinator, but the
	// domain is Cocoa either way.
	NSError *error = operation.errors.firstObject;
	XCTAssertEqualObjects(error.domain, NSCocoaErrorDomain);
}

- (void)testExecuteWithOnlyADocumentDependencyDoesNotDelete {
	// The `break` at the document branch means a document dependency by itself
	// never sets deleteFile, so nothing is deleted.
	NSURL *directory = [self newTemporaryDirectory];
	// The store is keyed by document name in the host's shared tmp; the unique
	// fixture directory goes into the name so the store starts empty.
	NSURL *documentURL = [directory URLByAppendingPathComponent:
						  [NSString stringWithFormat:@"document-%@.mad", directory.lastPathComponent]];
	MADocument *document = [[MADocument alloc] initWithFileURL:documentURL];
	[[NSFileManager defaultManager] createFileAtPath:documentURL.path contents:[NSData data] attributes:nil];

	MADDeleteFileTestDependency *dependency = [[MADDeleteFileTestDependency alloc] init];
	dependency.document = document;

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:documentURL.path]);
}

- (void)testCancelledExecuteFinishesAndDeletesNothing {
	NSURL *directory = [self newTemporaryDirectory];
	MADOperationUniqueUrlForFilename *urlOperation = [self newUrlOperationInDirectory:directory
																				named:@"cancelled"];
	NSURL *fileURL = urlOperation.uniqueUrl;
	XCTAssertTrue([[NSFileManager defaultManager] createFileAtPath:fileURL.path
														  contents:[NSData data]
													   attributes:nil]);

	MADDeleteFileTestResults *results = [[MADDeleteFileTestResults alloc] init];
	results.success = NO;

	MADOperationDeleteFile *operation = [[MADOperationDeleteFile alloc] init];
	[operation addDependency:urlOperation];
	[operation addDependency:results];
	[operation cancel];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
}

@end
#endif
