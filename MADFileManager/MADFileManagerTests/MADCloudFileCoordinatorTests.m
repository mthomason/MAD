//
//  MADCloudFileCoordinatorTests.m
//  MADFileManagerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADCloudFileCoordinator.  iCloud is not offered in this build
//  and the simulator has no ubiquity container (URLForUbiquityContainerIdentifier:
//  answers nil), which is the state these tests pin: the coordinator has to
//  tolerate a missing container, answer NO for every create, and still drive
//  its NSMetadataQuery.
//
//  Every coordinator built here is kept alive and has its private
//  documentsDirectoryQueue drained before it is released.  -init… queues a
//  barrier block that assigns _documentsDirectory through a weak self with no
//  nil check, so releasing a coordinator first segfaults at 0x10 (see BUGS.md).
//

#import <XCTest/XCTest.h>

#import "MADCloudFileCoordinator.h"

#import <Foundation/NSMetadata.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSURL.h>

// Implemented but not declared in the header.
@interface MADCloudFileCoordinator (TestAccess)
- (NSURL *)documentURLForName:(NSString *)name extention:(NSString *)extention
					fileGroup:(NSString *)fileGroup;
- (id)debugQuickLookObject;
@end

@interface MADCloudFileCoordinatorTests : XCTestCase

@property (nonatomic, strong) NSMutableArray <MADCloudFileCoordinator *> *coordinators;

@end

#pragma mark - Query recorder

// Counts query control without touching the iCloud machinery NSMetadataQuery
// needs to actually start.
@interface MADRecordingMetadataQuery : NSMetadataQuery

@property (nonatomic, assign) NSUInteger startQueryCount;
@property (nonatomic, assign) NSUInteger stopQueryCount;

@end

@implementation MADRecordingMetadataQuery

- (BOOL)startQuery { self.startQueryCount++; return YES; }
- (void)stopQuery { self.stopQueryCount++; }

@end

@implementation MADCloudFileCoordinatorTests

- (void)setUp {
	[super setUp];
	self.coordinators = [NSMutableArray array];
}

- (void)tearDown {
	// Keep each coordinator alive until its queued documents-directory block has
	// run, then let them go (BUGS.md).
	for (MADCloudFileCoordinator *coordinator in self.coordinators) {
		dispatch_queue_t queue = [coordinator valueForKey:@"documentsDirectoryQueue"];
		if (queue != NULL) dispatch_sync(queue, ^{ });
	}
	[self.coordinators removeAllObjects];
	self.coordinators = nil;
	[super tearDown];
}

- (MADCloudFileCoordinator *)keep:(MADCloudFileCoordinator *)coordinator {
	if (coordinator != nil) [self.coordinators addObject:coordinator];
	return coordinator;
}

- (MADCloudFileCoordinator *)coordinator {
	return [self keep:[[MADCloudFileCoordinator alloc] initWithPathExtension:@"mad"
																  identifier:nil
													 firstQueryUpdateHandler:nil]];
}

- (void)spinTheMainQueue {
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
}

#pragma mark - Constants

- (void)testNotificationNames {
	XCTAssertEqualObjects(MADNotificationCloudActivityStarted, @"MADNotificationCloudActivityStarted");
	XCTAssertEqualObjects(MADNotificationCloudActivityCompleted, @"MADNotificationCloudActivityCompleted");
}

#pragma mark - Initialization

- (void)testInitConfiguresTheMetadataQuery {
	MADCloudFileCoordinator *coordinator = [self coordinator];
	NSMetadataQuery *query = [coordinator valueForKey:@"metadataQuery"];

	XCTAssertNotNil(query);
	XCTAssertEqualObjects(query.searchScopes, (@[NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
												NSMetadataQueryUbiquitousDocumentsScope]));
	XCTAssertEqualWithAccuracy(query.notificationBatchingInterval, 0.5, 0.0001);

	// Hoisted: commas inside [] still split an XCTest macro's arguments.
	NSPredicate *expectedPredicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)",
									  NSMetadataItemURLKey, @"mad"];
	XCTAssertEqualObjects(query.predicate, expectedPredicate);
}

- (void)testPredicateInitializerStoresThePredicate {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)",
							  NSMetadataItemURLKey, @"Report.mad"];

	MADCloudFileCoordinator *coordinator =
		[self keep:[[MADCloudFileCoordinator alloc] initWithPredicate:predicate
														   identifier:nil
											  firstQueryUpdateHandler:nil]];
	NSMetadataQuery *query = [coordinator valueForKey:@"metadataQuery"];

	XCTAssertEqualObjects(query.predicate, predicate);
}

- (void)testDocumentsDirectoryToleratesAMissingUbiquityContainer {
	MADCloudFileCoordinator *coordinator = [self coordinator];
	NSURL *ubiquityContainer = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];

	if (ubiquityContainer == nil) {
		XCTAssertNil(coordinator.documentsDirectory);
	} else {
		XCTAssertTrue([coordinator.documentsDirectory.path hasPrefix:(ubiquityContainer.path ?: @"")]);
		XCTAssertEqualObjects(coordinator.documentsDirectory.lastPathComponent, @"Documents");
	}
}

#pragma mark - Creating

- (void)testAnEmptyNameCannotBeCreated {
	MADCloudFileCoordinator *coordinator = [self coordinator];

	XCTAssertFalse([coordinator canCreateFileWithName:@""
											extention:@"mad"
											fileGroup:nil]);
}

- (void)testANameCannotBeCreatedWithoutAContainer {
	MADCloudFileCoordinator *coordinator = [self coordinator];
	NSURL *ubiquityContainer = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];

	if (ubiquityContainer != nil) {
		// A real container: the create probe builds a URL inside its Documents
		// directory and answers from what is on disk there.
		NSURL *documentURL = [coordinator documentURLForName:@"MADCloudFileCoordinatorTests"
												   extention:@"mad"
												   fileGroup:nil];
		XCTAssertEqualObjects(documentURL.lastPathComponent, @"MADCloudFileCoordinatorTests.mad");
		XCTAssertTrue([documentURL.path hasPrefix:(ubiquityContainer.path ?: @"")]);
		return;
	}

	XCTAssertFalse([coordinator canCreateFileWithName:@"New"
											extention:@"mad"
											fileGroup:nil]);
	XCTAssertNil([coordinator documentURLForName:@"New" extention:@"mad" fileGroup:nil]);
}

#pragma mark - Query control

- (void)testStartAndStopQueryDriveTheMetadataQueryOnTheMainQueue {
	// A real NSMetadataQuery never reports -isStarted without an iCloud
	// container, so the query is swapped for a recorder and the dispatch is
	// observed instead.
	MADCloudFileCoordinator *coordinator = [self coordinator];
	MADRecordingMetadataQuery *query = [[MADRecordingMetadataQuery alloc] init];
	[coordinator setValue:query forKey:@"metadataQuery"];

	[coordinator startQuery];
	XCTAssertEqual(query.startQueryCount, (NSUInteger)0, @"startQuery is dispatched, not direct");
	[self spinTheMainQueue];
	XCTAssertEqual(query.startQueryCount, (NSUInteger)1);

	[coordinator stopQuery];
	[self spinTheMainQueue];
	XCTAssertEqual(query.stopQueryCount, (NSUInteger)1);
}

- (void)testRefreshRestartsTheQueryInPlace {
	MADCloudFileCoordinator *coordinator = [self coordinator];
	MADRecordingMetadataQuery *query = [[MADRecordingMetadataQuery alloc] init];
	[coordinator setValue:query forKey:@"metadataQuery"];

	[coordinator refresh];

	// -refresh goes straight at the query, without the main-queue hop.
	XCTAssertEqual(query.stopQueryCount, (NSUInteger)1);
	XCTAssertEqual(query.startQueryCount, (NSUInteger)1);

	[coordinator refresh];
	XCTAssertEqual(query.stopQueryCount, (NSUInteger)2);
	XCTAssertEqual(query.startQueryCount, (NSUInteger)2);
}

#pragma mark - Description

- (void)testDebugQuickLookObjectNamesTheClass {
	MADCloudFileCoordinator *coordinator = [self coordinator];

	NSString *debug = [coordinator debugQuickLookObject];
	XCTAssertTrue([debug containsString:[[NSStringFromClass([MADCloudFileCoordinator class]) uppercaseString] copy]]);
}

@end
