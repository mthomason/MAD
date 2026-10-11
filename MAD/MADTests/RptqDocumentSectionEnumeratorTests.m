//
//  RptqDocumentSectionEnumeratorTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for the two enumerators in RptqDocumentSectionEnumerator.
//
//  RptqDocumentSectionEnumerator answers the document's actual RptqDocumentSection rows,
//  in row order, and its -nextObject is post-increment (row 0 comes out first).  Its
//  -nextObject never consults -count, so on a document with no query (count 0) it still
//  hands back the report header -- pinned below as it stands.
//
//  RptqDocumentSectionTypeEnumerator answers NSNumber section types.  Its -nextObject
//  pre-increments, so the first call skips row 0 (the report header), and it has no end:
//  past the last row it keeps answering GroupFooter.  Both are pinned without enumerating
//  past a fixed, small number of calls.
//

#import <XCTest/XCTest.h>

#import "RptqDocumentSectionEnumerator.h"
#import "MADStore.h"
#import "MADSortOrder.h"
#import "MADocumentSectionType.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

@interface RptqDocumentSectionEnumeratorTests : XCTestCase
@end

@implementation RptqDocumentSectionEnumeratorTests

#pragma mark - Fixture

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDocument *)documentWithDatabaseAndQueryInContext:(RptqStoreContext *)context {
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqDatabase *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = [context insertObjectForEntity:@"RptqQuery" identifier:20];
	[document addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];
	return document;
}

#pragma mark - RptqDocumentSectionEnumerator

- (void)testInitReadsTheMainQueryAndStartsAtZero {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];

	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	XCTAssertEqual(enumerator.count, (NSUInteger)5);
	XCTAssertEqual(enumerator.current, (NSUInteger)0);
}

- (void)testNextObjectIsPostIncrementSoRowZeroComesOutFirst {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	id first = [enumerator nextObject];
	id second = [enumerator nextObject];

	XCTAssertEqual(first, document.hasReportHeaderSection);
	XCTAssertEqual(second, document.hasPageHeaderSection);
	XCTAssertEqual(enumerator.current, (NSUInteger)2);
}

- (void)testAllObjectsReturnsEverySectionInRowOrder {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	NSArray *sections = [enumerator allObjects];

	XCTAssertEqual(sections.count, (NSUInteger)5);
	XCTAssertEqual(sections[0], document.hasReportHeaderSection);
	XCTAssertEqual(sections[1], document.hasPageHeaderSection);
	XCTAssertEqual(sections[2], document.hasDetailSection);
	XCTAssertEqual(sections[3], document.hasPageFooterSection);
	XCTAssertEqual(sections[4], document.hasReportFooterSection);
	XCTAssertEqual(enumerator.current, (NSUInteger)5);
}

- (void)testCountAddsTwoRowsPerGroup {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:MADSortOrderAccending
													andManagedObjectContext:context];
	[document.mainQuery addHasQueryGroupsObject:group];

	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	XCTAssertEqual(enumerator.count, (NSUInteger)7);
}

- (void)testNextObjectIgnoresTheCountWhenThereIsNoQuery {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	XCTAssertEqual(enumerator.count, (NSUInteger)0);
	// No query means no section count, but -nextObject still answers row 0.
	XCTAssertEqual([enumerator nextObject], document.hasReportHeaderSection);
	XCTAssertEqual(enumerator.current, (NSUInteger)1);
}

#pragma mark - RptqDocumentSectionTypeEnumerator

- (void)testTypeEnumeratorAllObjectsListsTheSkeletonRowTypes {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDocumentSectionTypeEnumerator *enumerator = [[RptqDocumentSectionTypeEnumerator alloc]
													 initWithQueryID:document.mainQuery.identifier
												managedObjectContext:context];

	NSArray *types = [enumerator allObjects];
	NSArray *expected = @[ @(MADDocumentSectionTypeReportHeader),
						   @(MADDocumentSectionTypePageHeader),
						   @(MADDocumentSectionTypeBody),
						   @(MADDocumentSectionTypePageFooter),
						   @(MADDocumentSectionTypeReportFooter) ];

	XCTAssertEqual(enumerator.count, (NSUInteger)5);
	XCTAssertEqualObjects(types, expected);
}

- (void)testTypeEnumeratorNextObjectSkipsRowZeroAndHasNoEnd {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDocumentSectionTypeEnumerator *enumerator = [[RptqDocumentSectionTypeEnumerator alloc]
													 initWithQueryID:document.mainQuery.identifier
												managedObjectContext:context];

	// Pre-increment: the report header (row 0) never comes out.
	NSNumber *first = [enumerator nextObject];
	XCTAssertEqualObjects(first, @(MADDocumentSectionTypePageHeader));

	// Past the last row it keeps answering GroupFooter rather than nil.
	NSNumber *pastTheEnd = nil;
	for (NSUInteger call = 0; call < 9; call++) {
		pastTheEnd = [enumerator nextObject];
	}
	XCTAssertEqualObjects(pastTheEnd, @(MADDocumentSectionTypeGroupFooter));
}

@end
