//
//  MADLocalFileCoordinatorTests.m
//  MADFileManagerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADLocalFileCoordinator.  The coordinator works against the
//  App Group's Documents directory -- that is baked into MADURLFactory and
//  cannot be redirected -- so every test claims a private path extension
//  (a UUID-suffixed one) and creates/removes only files carrying it.
//
//  The suite pins two live defects, both called out in BUGS.md:
//    - -removeFileAtURL: reports the removed URL in the *updatedURLs* box and
//      leaves removedURLs empty (the local arrays are handed over swapped).
//    - -documentsDirectory is @dynamic with only a getter, so the protocol's
//      setter raises.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADApplication.h>

#import "MADFileCoordinatorDelegate.h"
#import "MADLocalFileCoordinator.h"

// Implemented but not declared in the header.
@interface MADLocalFileCoordinator (TestAccess)
- (id)debugQuickLookObject;
@end

#pragma mark - Test delegate

@interface MADRecordingFileCoordinatorDelegate : NSObject <MADFileCoordinatorDelegate>

@property (nonatomic, strong) NSArray *lastInsertedURLs;
@property (nonatomic, strong) NSArray *lastRemovedURLs;
@property (nonatomic, strong) NSArray *lastUpdatedURLs;
@property (nonatomic, strong) NSError *lastFailureError;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, assign) NSUInteger updateCount;
@property (nonatomic, assign) NSUInteger failureCount;

@end

@implementation MADRecordingFileCoordinatorDelegate {
	BOOL _fulfilled;
}

- (void)recordAndFulfill {
	if (!_fulfilled && self.expectation != nil) {
		_fulfilled = YES;
		[self.expectation fulfill];
	}
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
											 removedURLs:(NSArray *)removedURLs
											 updatedURLs:(NSArray *)updatedURLs {
	self.lastInsertedURLs = insertedURLs;
	self.lastRemovedURLs = removedURLs;
	self.lastUpdatedURLs = updatedURLs;
	self.updateCount++;
	[self recordAndFulfill];
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
											 removedMetaDatum:(NSArray *)removedMetaDatum
											 updatedMetaDatum:(NSArray *)updatedMetaDatum
												   completion:(void (^)(BOOL success, NSError *error))completion { }

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self recordAndFulfill];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self recordAndFulfill];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self recordAndFulfill];
}

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self recordAndFulfill];
}

@end

#pragma mark - Tests

@interface MADLocalFileCoordinatorTests : XCTestCase

@property (nonatomic, copy) NSString *extensionName;
@property (nonatomic, strong) MADRecordingFileCoordinatorDelegate *delegate;

@end

@implementation MADLocalFileCoordinatorTests

- (void)setUp {
	[super setUp];
	self.extensionName = [@"mft" stringByAppendingString:NSUUID.UUID.UUIDString.lowercaseString];
	self.delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
}

- (void)tearDown {
	NSURL *documents = [[NSFileManager defaultManager]
						containerURLForSecurityApplicationGroupIdentifier:[MADApplication groupIdentifier]];
	documents = [documents URLByAppendingPathComponent:@"Documents" isDirectory:YES];
	NSArray <NSURL *> *contents = documents ? [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documents
																			includingPropertiesForKeys:nil
																							   options:0
																								 error:NULL] : @[];
	for (NSURL *URL in contents) {
		if ([URL.pathExtension isEqualToString:self.extensionName]) {
			[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
		}
	}
	self.delegate = nil;
	self.extensionName = nil;
	[super tearDown];
}

- (MADLocalFileCoordinator *)coordinator {
	return [[MADLocalFileCoordinator alloc] initWithPathExtension:self.extensionName
													   identifier:[MADApplication groupIdentifier]
										  firstQueryUpdateHandler:nil];
}

- (NSURL *)writeFileNamed:(NSString *)name {
	NSURL *URL = [self.coordinator.documentsDirectory URLByAppendingPathComponent:name];
	[@"report" writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	return URL;
}

- (NSURL *)documentURLForName:(NSString *)name {
	return [[self.coordinator.documentsDirectory URLByAppendingPathComponent:name]
			URLByAppendingPathExtension:self.extensionName];
}

- (void)waitForTheDelegate {
	[self waitForExpectations:@[self.delegate.expectation] timeout:5.0];
}

#pragma mark - Initialization

- (void)testInitTargetsTheGroupDocumentsDirectory {
	MADLocalFileCoordinator *coordinator = [self coordinator];

	NSURL *container = [[NSFileManager defaultManager]
						containerURLForSecurityApplicationGroupIdentifier:[MADApplication groupIdentifier]];
	XCTAssertNotNil(container);
	XCTAssertTrue([coordinator.documentsDirectory.path hasPrefix:(container.path ?: @"")]);
	XCTAssertEqualObjects(coordinator.documentsDirectory.lastPathComponent, @"Documents");
}

- (void)testDocumentsDirectoryHasNoSetter {
	// BUGS.md: the protocol declares documentsDirectory readwrite, but the
	// class declares it @dynamic and only -documentsDirectory is implemented.
	MADLocalFileCoordinator *coordinator = [self coordinator];

	XCTAssertFalse([coordinator respondsToSelector:@selector(setDocumentsDirectory:)]);
	XCTAssertThrowsSpecificNamed([coordinator setDocumentsDirectory:coordinator.documentsDirectory],
								 NSException, NSInvalidArgumentException);
}

- (void)testDebugQuickLookObjectListsTheGroupAndContents {
	MADLocalFileCoordinator *coordinator = [self coordinator];

	NSString *debug = [coordinator debugQuickLookObject];
	XCTAssertTrue([debug containsString:[[NSStringFromClass([MADLocalFileCoordinator class]) uppercaseString] copy]]);
	XCTAssertTrue([debug containsString:[MADApplication groupIdentifier]]);
	XCTAssertTrue([debug containsString:@"Current contents:"]);
}

#pragma mark - canCreateFileWithName:extention:fileGroup:

- (void)testAnEmptyNameCannotBeCreated {
	MADLocalFileCoordinator *coordinator = [self coordinator];

	XCTAssertFalse([coordinator canCreateFileWithName:@""
											extention:self.extensionName
											fileGroup:[MADApplication groupIdentifier]]);
}

- (void)testAFreshNameCanBeCreatedAndAnExistingOneCannot {
	MADLocalFileCoordinator *coordinator = [self coordinator];

	XCTAssertTrue([coordinator canCreateFileWithName:@"Fresh"
										   extention:self.extensionName
										   fileGroup:[MADApplication groupIdentifier]]);

	[self writeFileNamed:[@"Fresh" stringByAppendingPathExtension:self.extensionName]];

	XCTAssertFalse([coordinator canCreateFileWithName:@"Fresh"
											extention:self.extensionName
											fileGroup:[MADApplication groupIdentifier]]);
}

#pragma mark - refresh

- (void)testRefreshReportsANewFileAsInsertedAndRunsTheFirstQueryHandler {
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *inserted = [self writeFileNamed:[@"One" stringByAppendingPathExtension:self.extensionName]];

	XCTestExpectation *handlerCalled = [self expectationWithDescription:@"first query handler"];
	MADLocalFileCoordinator *handlerCoordinator =
		[[MADLocalFileCoordinator alloc] initWithPathExtension:self.extensionName
													identifier:[MADApplication groupIdentifier]
									   firstQueryUpdateHandler:^{
			[handlerCalled fulfill];
		}];
	handlerCoordinator.delegate = self.delegate;

	self.delegate.expectation = [self expectationWithDescription:@"contents updated"];
	[handlerCoordinator refresh];
	[self waitForTheDelegate];

	XCTAssertEqualObjects(self.delegate.lastInsertedURLs, @[inserted]);
	XCTAssertEqualObjects(self.delegate.lastRemovedURLs, @[]);
	XCTAssertEqualObjects(self.delegate.lastUpdatedURLs, @[]);

	[self waitForExpectations:@[handlerCalled] timeout:5.0];
}

- (void)testRefreshReportsARemovedFileWhenFilesRemain {
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *first = [self writeFileNamed:[@"First" stringByAppendingPathExtension:self.extensionName]];
	NSURL *second = [self writeFileNamed:[@"Second" stringByAppendingPathExtension:self.extensionName]];

	self.delegate.expectation = [self expectationWithDescription:@"initial contents"];
	[coordinator refresh];
	[self waitForTheDelegate];
	XCTAssertEqual(self.delegate.lastInsertedURLs.count, (NSUInteger)2);

	[[NSFileManager defaultManager] removeItemAtURL:first error:NULL];

	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	delegate.expectation = [self expectationWithDescription:@"removal reported"];
	coordinator.delegate = delegate;
	[coordinator refresh];
	[self waitForExpectations:@[delegate.expectation] timeout:5.0];

	XCTAssertEqualObjects(delegate.lastRemovedURLs, @[first]);
	XCTAssertEqualObjects(delegate.lastInsertedURLs, @[]);
	XCTAssertEqual(delegate.lastUpdatedURLs.count, (NSUInteger)0);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:(second.path ?: @"")]);
}

- (void)testRefreshIsSilentWhenTheLastMatchingFileIsGone {
	// Quirk: an empty result set skips the whole comparison block, so losing the
	// last matching file produces no delegate callback at all.
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *only = [self writeFileNamed:[@"Only" stringByAppendingPathExtension:self.extensionName]];

	self.delegate.expectation = [self expectationWithDescription:@"initial contents"];
	[coordinator refresh];
	[self waitForTheDelegate];
	XCTAssertEqual(self.delegate.updateCount, (NSUInteger)1);

	[[NSFileManager defaultManager] removeItemAtURL:only error:NULL];

	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;
	[coordinator refresh];

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	XCTAssertEqual(delegate.updateCount, (NSUInteger)0);
}

#pragma mark - remove / duplicate / rename

- (void)testRemoveReportsTheURLAsUpdatedNotRemoved {
	// BUGS.md: the success branch hands the arrays over swapped.  The file is
	// deleted, but the delegate is told the URL was updated.
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *URL = [self writeFileNamed:[@"Doomed" stringByAppendingPathExtension:self.extensionName]];

	self.delegate.expectation = [self expectationWithDescription:@"remove completed"];
	[coordinator removeFileAtURL:URL];
	[self waitForTheDelegate];

	XCTAssertEqualObjects(self.delegate.lastUpdatedURLs, @[URL]);
	XCTAssertEqualObjects(self.delegate.lastRemovedURLs, @[]);
	XCTAssertEqualObjects(self.delegate.lastInsertedURLs, @[]);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")]);
}

- (void)testRemoveOfAMissingFileReportsAFailure {
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *URL = [self documentURLForName:@"NeverWritten"];

	self.delegate.expectation = [self expectationWithDescription:@"remove failed"];
	[coordinator removeFileAtURL:URL];
	[self waitForTheDelegate];

	XCTAssertEqual(self.delegate.failureCount, (NSUInteger)1);
	XCTAssertNotNil(self.delegate.lastFailureError);
	XCTAssertEqual(self.delegate.updateCount, (NSUInteger)0);
}

- (void)testDuplicateReportsTheCopyAsInserted {
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *URL = [self writeFileNamed:[@"Original" stringByAppendingPathExtension:self.extensionName]];

	self.delegate.expectation = [self expectationWithDescription:@"duplicate completed"];
	[coordinator duplicateFileAtURL:URL];
	[self waitForTheDelegate];

	XCTAssertEqual(self.delegate.lastInsertedURLs.count, (NSUInteger)1);
	NSURL *copy = self.delegate.lastInsertedURLs.firstObject;
	XCTAssertNotEqualObjects(copy, URL);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:(copy.path ?: @"")]);
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")]);
}

- (void)testRenameReportsTheOldURLRemovedAndTheNewURLInserted {
	MADLocalFileCoordinator *coordinator = [self coordinator];
	coordinator.delegate = self.delegate;

	NSURL *URL = [self writeFileNamed:[@"Before" stringByAppendingPathExtension:self.extensionName]];

	self.delegate.expectation = [self expectationWithDescription:@"rename completed"];
	[coordinator renameFileAtURL:URL toName:@"After"];
	[self waitForTheDelegate];

	XCTAssertEqual(self.delegate.lastRemovedURLs.count, (NSUInteger)1);
	XCTAssertEqual(self.delegate.lastInsertedURLs.count, (NSUInteger)1);
	NSURL *renamed = self.delegate.lastInsertedURLs.firstObject;
	XCTAssertEqualObjects(renamed.pathExtension, self.extensionName);
	XCTAssertEqualObjects(renamed.lastPathComponent.stringByDeletingPathExtension, @"After");
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:(renamed.path ?: @"")]);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")]);
}

@end
