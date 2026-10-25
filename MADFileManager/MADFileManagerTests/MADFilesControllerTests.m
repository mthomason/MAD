//
//  MADFilesControllerTests.m
//  MADFileManagerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADFilesController, the model in front of the file coordinators.
//  A hand-rolled MADFileCoordinatorProtocol double stands in for the local and
//  cloud coordinators, and the controller is driven through the coordinator
//  delegate callbacks it will really see.  The controller's own delegate runs on
//  a private serial NSOperationQueue so every test can wait for the work to land.
//
//  Pinned here:
//    - the sortComparator argument to -initWithFileCoordinator:... is accepted
//      and never used; inserts always land in finder order.
//    - +getFileStorageLocationsForUbiquityIdentifier:... hands the Data
//      directory back as `documents` and the Documents directory back as `data`.
//    - -fileCoordinatorDidFailRenamingFileAtURL: gates the renaming callback on
//      the delegate implementing the *removing* callback.
//    - -setFileCoordinator: raises NSUnknownKeyException on the delegate queue
//      when anything is tracked (URLs passed as metadata), so the swap is only
//      covered for the empty case.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADApplication.h>

#import <Foundation/NSKeyValueCoding.h>
#import <dispatch/dispatch.h>

#import "MADFilesController.h"
#import "MADFilesControllerDelegate.h"
#import "MADFileCoordinatorProtocol.h"
#import "MADFileCoordinatorDelegate.h"
#import "MADLocalFileCoordinator.h"
#import "MADCloudFileCoordinator.h"
#import "MADMetaData.h"

// The controller adopts MADFileCoordinatorDelegate in its class extension, so
// the callbacks are not visible to callers; declare them for the tests.
@interface MADFilesController (TestAccess) <MADFileCoordinatorDelegate>
@end

#pragma mark - Coordinator double

@interface MADTestFileCoordinator : NSObject <MADFileCoordinatorProtocol>

@property (nonatomic, weak) id <MADFileCoordinatorDelegate> delegate;
@property (nonatomic, copy) NSURL *documentsDirectory;

@property (nonatomic, assign) NSUInteger startQueryCount;
@property (nonatomic, assign) NSUInteger stopQueryCount;
@property (nonatomic, assign) NSUInteger refreshCount;
@property (nonatomic, strong) NSURL *lastRemovedURL;
@property (nonatomic, strong) NSURL *lastDuplicatedURL;
@property (nonatomic, strong) NSURL *lastRenamedURL;
@property (nonatomic, copy)   NSString *lastRenameName;
@property (nonatomic, assign) BOOL canCreateAnswer;
@property (nonatomic, strong) NSArray *lastCanCreateArguments;

@end

@implementation MADTestFileCoordinator

- (void)refresh { self.refreshCount++; }
- (void)startQuery { self.startQueryCount++; }
- (void)stopQuery { self.stopQueryCount++; }

- (void)removeFileAtURL:(NSURL *)URL { self.lastRemovedURL = URL; }
- (void)duplicateFileAtURL:(NSURL *)URL { self.lastDuplicatedURL = URL; }

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {
	self.lastRenamedURL = URL;
	self.lastRenameName = name;
}

- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
					fileGroup:(NSString *)fileGroup {
	self.lastCanCreateArguments = @[name ?: @"", extention ?: @"", fileGroup ?: @""];
	return self.canCreateAnswer;
}

@end

#pragma mark - Controller delegate doubles

@interface MADRecordingFilesControllerDelegate : NSObject <MADFilesControllerDelegate>

@property (nonatomic, strong) NSMutableArray <MADMetaData *> *inserted;
@property (nonatomic, strong) NSMutableArray <MADMetaData *> *removed;
@property (nonatomic, strong) NSMutableArray <MADMetaData *> *updated;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *insertedIndexes;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *removedIndexes;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *updatedIndexes;
@property (nonatomic, assign) NSUInteger willChangeCount;
@property (nonatomic, assign) NSUInteger didChangeCount;
@property (nonatomic, assign) NSUInteger failureCount;

@end

@implementation MADRecordingFilesControllerDelegate

- (instancetype)init {
	if (self = [super init]) {
		_inserted = [NSMutableArray array];
		_removed = [NSMutableArray array];
		_updated = [NSMutableArray array];
		_insertedIndexes = [NSMutableArray array];
		_removedIndexes = [NSMutableArray array];
		_updatedIndexes = [NSMutableArray array];
	}
	return self;
}

- (void)filesControllerWillChangeContent:(MADFilesController *)filesController {
	self.willChangeCount++;
}

- (void)filesController:(MADFilesController *)filesController
	  didInsertFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index {
	[self.inserted addObject:fileInfo];
	[self.insertedIndexes addObject:@(index)];
}

- (void)filesController:(MADFilesController *)filesController
	  didRemoveFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index {
	[self.removed addObject:fileInfo];
	[self.removedIndexes addObject:@(index)];
}

- (void)filesController:(MADFilesController *)filesController
	  didUpdateFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index {
	[self.updated addObject:fileInfo];
	[self.updatedIndexes addObject:@(index)];
}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController
							 completion:(void (^)(BOOL success, NSError *error))completion {
	self.didChangeCount++;
	if (completion != nil) completion(YES, nil);
}

- (void)filesController:(MADFilesController *)filesController
didFailCreatingFileInfo:(MADMetaData *)fileInfo
			  withError:(NSError *)error {
	self.failureCount++;
}

- (void)filesController:(MADFilesController *)filesController
didFailRemovingFileInfo:(MADMetaData *)fileInfo
			  withError:(NSError *)error {
	self.failureCount++;
}

- (void)filesController:(MADFilesController *)filesController
didFailDuplicatingFileInfo:(MADMetaData *)fileInfo
			  withError:(NSError *)error {
	self.failureCount++;
}

- (void)filesController:(MADFilesController *)filesController
 didFailRenamingFileInfo:(MADMetaData *)fileInfo
			  withError:(NSError *)error {
	self.failureCount++;
}

@end

// Implements only the renaming failure callback: with this delegate the
// controller silently drops a renaming failure (see the class comment).
@interface MADRenamingOnlyFilesControllerDelegate : NSObject <MADFilesControllerDelegate>

@property (nonatomic, assign) NSUInteger failureCount;

@end

@implementation MADRenamingOnlyFilesControllerDelegate

- (void)filesController:(MADFilesController *)filesController
 didFailRenamingFileInfo:(MADMetaData *)fileInfo
			  withError:(NSError *)error {
	self.failureCount++;
}

@end

#pragma mark - Tests

@interface MADFilesControllerTests : XCTestCase

@property (nonatomic, strong) NSURL *directory;
@property (nonatomic, strong) MADTestFileCoordinator *coordinator;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, strong) MADRecordingFilesControllerDelegate *delegate;
// Held strongly until its documents-directory block has run (BUGS.md).
@property (nonatomic, strong) id <MADFileCoordinatorProtocol> cloudCoordinator;

@end

@implementation MADFilesControllerTests

- (void)setUp {
	[super setUp];
	self.directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]
								isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:self.directory
							 withIntermediateDirectories:YES attributes:nil error:NULL];

	self.coordinator = [[MADTestFileCoordinator alloc] init];
	self.coordinator.documentsDirectory = self.directory;

	self.delegateQueue = [[NSOperationQueue alloc] init];
	self.delegateQueue.maxConcurrentOperationCount = 1;

	self.delegate = [[MADRecordingFilesControllerDelegate alloc] init];
}

- (void)tearDown {
	if (self.cloudCoordinator != nil) {
		id coordinator = self.cloudCoordinator;
		dispatch_queue_t queue = [coordinator valueForKey:@"documentsDirectoryQueue"];
		if (queue != NULL) dispatch_sync(queue, ^{ });
		self.cloudCoordinator = nil;
	}

	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	self.directory = nil;
	self.coordinator = nil;
	self.delegateQueue = nil;
	self.delegate = nil;
	[super tearDown];
}

- (MADFilesController *)controller {
	MADFilesController *controller =
		[[MADFilesController alloc] initWithFileCoordinator:self.coordinator
											  delegateQueue:self.delegateQueue
											 sortComparator:nil];
	controller.delegate = self.delegate;
	return controller;
}

- (NSURL *)writeFileNamed:(NSString *)name {
	NSURL *URL = [self.directory URLByAppendingPathComponent:name];
	[@"report" writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	return URL;
}

- (void)waitForTheDelegateQueue {
	[self.delegateQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Initialization

- (void)testInitWiresTheControllerAsTheCoordinatorsDelegate {
	MADFilesController *controller = [self controller];

	XCTAssertEqual(self.coordinator.delegate, controller);
	XCTAssertEqual(controller.fileCoordinator, self.coordinator);
}

- (void)testInitFallsBackToTheMainQueue {
	MADFilesController *controller =
		[[MADFilesController alloc] initWithFileCoordinator:self.coordinator
											  delegateQueue:nil
											 sortComparator:nil];

	XCTAssertEqual([controller valueForKey:@"delegateQueue"], [NSOperationQueue mainQueue]);
}

- (void)testDocumentDirectoryComesFromTheCoordinator {
	MADFilesController *controller = [self controller];

	XCTAssertEqualObjects(controller.documentDirectory, self.directory);
}

#pragma mark - Forwarding

- (void)testSearchingAndRefreshForwardToTheCoordinator {
	MADFilesController *controller = [self controller];

	[controller startSearching];
	[controller stopSearching];
	[controller refresh];

	XCTAssertEqual(self.coordinator.startQueryCount, (NSUInteger)1);
	XCTAssertEqual(self.coordinator.stopQueryCount, (NSUInteger)1);
	XCTAssertEqual(self.coordinator.refreshCount, (NSUInteger)1);
}

- (void)testFileInfoCommandsForwardToTheCoordinator {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"Doc.mad"];
	MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];

	[controller removeFileInfo:fileInfo];
	XCTAssertEqualObjects(self.coordinator.lastRemovedURL, URL);

	[controller duplicateFileInfo:fileInfo];
	XCTAssertEqualObjects(self.coordinator.lastDuplicatedURL, URL);

	[controller renameFileInfo:fileInfo toName:@"Other"];
	XCTAssertEqualObjects(self.coordinator.lastRenamedURL, URL);
	XCTAssertEqualObjects(self.coordinator.lastRenameName, @"Other");

	self.coordinator.canCreateAnswer = YES;
	XCTAssertTrue([controller canCreateFileInfoWithName:@"New" extention:@"mad" fileGroup:@"group"]);
	XCTAssertEqualObjects(self.coordinator.lastCanCreateArguments, (@[@"New", @"mad", @"group"]));
}

#pragma mark - Inserting

- (void)testInsertedURLsAreTrackedInFinderOrder {
	MADFilesController *controller = [self controller];

	// Deliberately handed over in reverse order.
	NSURL *bravo = [self writeFileNamed:@"bravo.mad"];
	NSURL *alpha = [self writeFileNamed:@"alpha.mad"];

	NSArray *inserted = @[bravo, alpha];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(controller.count, (NSUInteger)2);
	XCTAssertEqualObjects(controller[0].fileSystemName, @"alpha.mad");
	XCTAssertEqualObjects(controller[1].fileSystemName, @"bravo.mad");

	XCTAssertEqual(self.delegate.willChangeCount, (NSUInteger)1);
	XCTAssertEqual(self.delegate.didChangeCount, (NSUInteger)1);
	XCTAssertEqualObjects(self.delegate.insertedIndexes, (@[@0, @1]));
}

- (void)testAlreadyTrackedInsertIsIgnored {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"once.mad"];

	NSArray *inserted = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];
	XCTAssertEqual(controller.count, (NSUInteger)1);

	// The same URL again: nothing is untracked, removed or updated, so the whole
	// pass is skipped -- no delegate traffic at all.
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(controller.count, (NSUInteger)1);
	XCTAssertEqual(self.delegate.willChangeCount, (NSUInteger)1);
	XCTAssertEqual(self.delegate.didChangeCount, (NSUInteger)1);
	XCTAssertEqual(self.delegate.inserted.count, (NSUInteger)1);
}

#pragma mark - Removing / updating

- (void)testRemovingATrackedURLUntracksIt {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"doomed.mad"];

	NSArray *inserted = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	NSArray *removed = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:@[]
													 removedURLs:removed
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(controller.count, (NSUInteger)0);
	XCTAssertEqual(self.delegate.removed.count, (NSUInteger)1);
	XCTAssertEqualObjects(self.delegate.removedIndexes, (@[@0]));
}

- (void)testRemovingAnUntrackedURLIsIgnored {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"stranger.mad"];

	NSArray *removed = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:@[]
													 removedURLs:removed
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(controller.count, (NSUInteger)0);
	XCTAssertEqual(self.delegate.willChangeCount, (NSUInteger)0);
	XCTAssertEqual(self.delegate.removed.count, (NSUInteger)0);
}

- (void)testUpdatedMetadataReplacesTheTrackedEntry {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"doc.mad"];

	NSArray *inserted = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	NSArray *updated = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:@[]
													 removedURLs:@[]
													 updatedURLs:updated];
	[self waitForTheDelegateQueue];

	// MADMetaData equality keys on the file name, so a fresh metadata object for
	// the same URL finds its index.
	XCTAssertEqual(controller.count, (NSUInteger)1);
	XCTAssertEqual(self.delegate.updated.count, (NSUInteger)1);
	XCTAssertEqualObjects(self.delegate.updatedIndexes, (@[@0]));
}

#pragma mark - Sorting

- (void)testTheSortComparatorArgumentIsIgnored {
	// BUGS.md: -initWithFileCoordinator:delegateQueue:sortComparator: accepts a
	// comparator and never stores or calls it; inserts are ordered by
	// finderSortWithLocale.
	NSComparisonResult (^reversed)(MADMetaData *, MADMetaData *) =
		^NSComparisonResult(MADMetaData *__unused lhs, MADMetaData *__unused rhs) {
			return NSOrderedDescending;
		};

	MADFilesController *controller =
		[[MADFilesController alloc] initWithFileCoordinator:self.coordinator
											  delegateQueue:self.delegateQueue
											 sortComparator:reversed];
	controller.delegate = self.delegate;

	NSURL *alpha = [self writeFileNamed:@"alpha.mad"];
	NSURL *bravo = [self writeFileNamed:@"bravo.mad"];
	NSArray *inserted = @[alpha, bravo];

	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	// The comparator would keep alpha first and say descending; finder order
	// still wins.
	XCTAssertEqualObjects(controller[0].fileSystemName, @"alpha.mad");
	XCTAssertEqualObjects(controller[1].fileSystemName, @"bravo.mad");
}

#pragma mark - setFileInfoHasNewContents:

- (void)testSetFileInfoHasNewContentsReplacesAndNotifies {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"dot.mad"];

	NSArray *inserted = @[URL];
	[controller fileCoordinatorDidUpdateContentsWithInsertedURLs:inserted
													 removedURLs:@[]
													 updatedURLs:@[]];
	[self waitForTheDelegateQueue];

	MADMetaData *fileInfo = controller[0];
	[controller setFileInfoHasNewContents:fileInfo];
	// The replacement runs first on the controller's private metadata queue,
	// which only then queues the delegate work; drain it before waiting.
	dispatch_queue_t metadataQueue = [controller valueForKey:@"fileMetaDataQueue"];
	dispatch_sync(metadataQueue, ^{ });
	[self waitForTheDelegateQueue];

	XCTAssertEqual(controller.count, (NSUInteger)1);
	XCTAssertEqual(self.delegate.updated.count, (NSUInteger)1);
	XCTAssertEqualObjects(self.delegate.updatedIndexes, (@[@0]));
	XCTAssertEqual(self.delegate.willChangeCount, (NSUInteger)2);
	XCTAssertEqual(self.delegate.didChangeCount, (NSUInteger)2);
}

#pragma mark - Failure forwarding

- (void)testFailuresForwardToTheDelegate {
	MADFilesController *controller = [self controller];
	NSURL *URL = [self writeFileNamed:@"fail.mad"];
	NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

	[controller fileCoordinatorDidFailCreatingFileAtURL:URL withError:error];
	[controller fileCoordinatorDidFailRemovingFileAtURL:URL withError:error];
	[controller fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
	[controller fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(self.delegate.failureCount, (NSUInteger)4);
}

- (void)testRenamingFailureIsGatedOnTheRemovingCallback {
	// BUGS.md: -fileCoordinatorDidFailRenamingFileAtURL: checks
	// respondsToSelector: for the *removing* callback before sending the
	// renaming one, so a delegate that implements only the renaming callback
	// never hears about a rename failure.
	MADFilesController *controller = [self controller];
	MADRenamingOnlyFilesControllerDelegate *delegate = [[MADRenamingOnlyFilesControllerDelegate alloc] init];
	controller.delegate = delegate;

	NSURL *URL = [self writeFileNamed:@"fail.mad"];
	NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

	[controller fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
	[self waitForTheDelegateQueue];

	XCTAssertEqual(delegate.failureCount, (NSUInteger)0);
}

#pragma mark - Swapping coordinators

- (void)testSettingANewCoordinatorStopsTheOldOneAndStartsTheNewOne {
	// The swap can only be exercised while nothing is tracked.  With a file
	// tracked, -setFileCoordinator: passes the tracked list through
	// -valueForKey:@"URL" and hands URLs in where MADMetaData is expected, which
	// raises NSUnknownKeyException on the delegate queue and terminates the
	// process (see BUGS.md).  Nothing here is allowed to crash the suite, so the
	// populated case stays untested until that is fixed.
	MADFilesController *controller = [self controller];

	MADTestFileCoordinator *replacement = [[MADTestFileCoordinator alloc] init];
	replacement.documentsDirectory = self.directory;
	MADTestFileCoordinator *old = self.coordinator;

	controller.fileCoordinator = replacement;
	[self waitForTheDelegateQueue];

	XCTAssertEqual(old.stopQueryCount, (NSUInteger)1);
	XCTAssertNil(old.delegate);
	XCTAssertEqual(replacement.startQueryCount, (NSUInteger)1);
	XCTAssertEqual(replacement.delegate, controller);
	XCTAssertEqual(controller.count, (NSUInteger)0);
	XCTAssertEqual(self.delegate.removed.count, (NSUInteger)0);
}

#pragma mark - Factory

- (void)testFactoryBuildsAControllerOverARealCoordinator {
	MADFilesController *local =
		[MADFilesController newFilesControllerWithPathExtension:@"mad"
												  storageOption:MADAppStorageLocal
													 identifier:[MADApplication groupIdentifier]
											  firstQueryHandler:nil];
	XCTAssertTrue([local.fileCoordinator isKindOfClass:[MADLocalFileCoordinator class]]);
	XCTAssertEqual([local valueForKey:@"delegateQueue"], [NSOperationQueue mainQueue]);

	MADFilesController *cloud =
		[MADFilesController newFilesControllerWithLastPathComponent:@"Report.mad"
													  storageOption:MADAppStorageCloud
														 identifier:nil
												  firstQueryHandler:nil];
	XCTAssertTrue([cloud.fileCoordinator isKindOfClass:[MADCloudFileCoordinator class]]);

	// The cloud coordinator must outlive its queued documents-directory block or
	// the process segfaults when it is released (BUGS.md).
	self.cloudCoordinator = cloud.fileCoordinator;
}

#pragma mark - Cloud availability

- (void)testCloudIsNotDesiredOrAvailableInThisBuild {
	XCTAssertFalse([MADFilesController isCloudDesired]);
	XCTAssertFalse([MADFilesController isCloudReadilyAvailable]);
}

- (void)testStorageLocationsWithoutCloudAnswerLocalDirectories {
	// BUGS.md: the two URL arguments are crossed -- `documents` is handed the
	// Data directory and `data` the Documents directory.  The only caller marks
	// both unused, so nothing breaks today.
	__block BOOL completionCalled = NO;
	__block BOOL cloudAvailable = YES;
	__block NSURL *documents = nil;
	__block NSURL *data = nil;

	[MADFilesController getFileStorageLocationsForUbiquityIdentifier:nil
													 groupIdentifier:[MADApplication groupIdentifier]
															   delay:^{ }
														  completion:^(BOOL cloudAvailableAnswer,
																	   NSURL *documentsAnswer,
																	   NSURL *dataAnswer) {
		completionCalled = YES;
		cloudAvailable = cloudAvailableAnswer;
		documents = documentsAnswer;
		data = dataAnswer;
	}];

	XCTAssertTrue(completionCalled);
	XCTAssertFalse(cloudAvailable);
	XCTAssertNotNil(documents);
	XCTAssertNotNil(data);
	XCTAssertEqualObjects(documents.lastPathComponent, @"Data");
	XCTAssertEqualObjects(data.lastPathComponent, @"Documents");
}

@end
