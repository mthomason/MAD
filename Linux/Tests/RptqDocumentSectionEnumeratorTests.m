//
//  RptqDocumentSectionEnumeratorTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/RptqDocumentSectionEnumeratorTests.m: the two
//  enumerators in RptqDocumentSectionEnumerator.
//
//  RptqDocumentSectionEnumerator answers the document's actual
//  RptqDocumentSection rows, in row order, and its -nextObject is post-increment
//  (row 0 comes out first).  Its -nextObject never consults -count, so on a
//  document with no query (count 0) it still hands back the report header --
//  pinned below as it stands.
//
//  RptqDocumentSectionTypeEnumerator answers NSNumber section types.  Its
//  -nextObject pre-increments, so the first call skips row 0 (the report header),
//  and it has no end: past the last row it keeps answering GroupFooter.  Both are
//  pinned without enumerating past a fixed, small number of calls.  The Xcode
//  suite's in-memory Core Data context is a real SQLite store under a per-test
//  temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/MADStore.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>

#pragma mark - Fixture

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

static RptqDocument *documentWithDatabaseAndQueryInContext(RptqStoreContext *context) {
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqDatabase *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = [context insertObjectForEntity:@"RptqQuery" identifier:20];
	[document addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];
	return document;
}

#pragma mark - RptqDocumentSectionEnumerator

static void testInitReadsTheMainQueryAndStartsAtZero(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);

	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	MAD_PASS(enumerator.count == (NSUInteger)5, "the five skeleton sections are counted");
	MAD_PASS(enumerator.current == (NSUInteger)0, "the enumerator starts at row 0");

	[enumerator release];
}

static void testNextObjectIsPostIncrementSoRowZeroComesOutFirst(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	id first = [enumerator nextObject];
	id second = [enumerator nextObject];

	MAD_PASS(first == document.hasReportHeaderSection, "row 0 is the report header");
	MAD_PASS(second == document.hasPageHeaderSection, "row 1 is the page header");
	MAD_PASS(enumerator.current == (NSUInteger)2, "two rows have come out");

	[enumerator release];
}

static void testAllObjectsReturnsEverySectionInRowOrder(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	NSArray *sections = [enumerator allObjects];

	MAD_PASS(sections.count == (NSUInteger)5, "every skeleton section comes out");
	MAD_PASS(sections[0] == document.hasReportHeaderSection, "row 0 is the report header");
	MAD_PASS(sections[1] == document.hasPageHeaderSection, "row 1 is the page header");
	MAD_PASS(sections[2] == document.hasDetailSection, "row 2 is the detail section");
	MAD_PASS(sections[3] == document.hasPageFooterSection, "row 3 is the page footer");
	MAD_PASS(sections[4] == document.hasReportFooterSection, "row 4 is the report footer");
	MAD_PASS(enumerator.current == (NSUInteger)5, "the enumerator consumed all five rows");

	[enumerator release];
}

static void testCountAddsTwoRowsPerGroup(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:MADSortOrderAccending
													andManagedObjectContext:context];
	[document.mainQuery addHasQueryGroupsObject:group];

	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	MAD_PASS(enumerator.count == (NSUInteger)7, "a group adds two rows to the count");

	[enumerator release];
}

static void testNextObjectIgnoresTheCountWhenThereIsNoQuery(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDocumentSectionEnumerator *enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];

	MAD_PASS(enumerator.count == (NSUInteger)0, "no query means no section count");
	// No query means no section count, but -nextObject still answers row 0.
	MAD_PASS([enumerator nextObject] == document.hasReportHeaderSection, "row 0 still comes out");
	MAD_PASS(enumerator.current == (NSUInteger)1, "the enumerator advanced past row 0");

	[enumerator release];
}

#pragma mark - RptqDocumentSectionTypeEnumerator

static void testTypeEnumeratorAllObjectsListsTheSkeletonRowTypes(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDocumentSectionTypeEnumerator *enumerator = [[RptqDocumentSectionTypeEnumerator alloc]
													 initWithQueryID:document.mainQuery.identifier
												managedObjectContext:context];

	NSArray *types = [enumerator allObjects];
	NSArray *expected = @[ @(MADDocumentSectionTypeReportHeader),
						   @(MADDocumentSectionTypePageHeader),
						   @(MADDocumentSectionTypeBody),
						   @(MADDocumentSectionTypePageFooter),
						   @(MADDocumentSectionTypeReportFooter) ];

	MAD_PASS(enumerator.count == (NSUInteger)5, "the type enumerator counts the five skeleton rows");
	MAD_PASS_EQUAL(types, expected, "the type enumerator lists the skeleton row types in order");

	[enumerator release];
}

static void testTypeEnumeratorNextObjectSkipsRowZeroAndHasNoEnd(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDocumentSectionTypeEnumerator *enumerator = [[RptqDocumentSectionTypeEnumerator alloc]
													 initWithQueryID:document.mainQuery.identifier
												managedObjectContext:context];

	// Pre-increment: the report header (row 0) never comes out.
	NSNumber *first = [enumerator nextObject];
	MAD_PASS_EQUAL(first, @(MADDocumentSectionTypePageHeader), "the first call skips row 0");

	// Past the last row it keeps answering GroupFooter rather than nil.
	NSNumber *pastTheEnd = nil;
	for (NSUInteger call = 0; call < 9; call++) {
		pastTheEnd = [enumerator nextObject];
	}
	MAD_PASS_EQUAL(pastTheEnd, @(MADDocumentSectionTypeGroupFooter), "past the last row it keeps answering GroupFooter");

	[enumerator release];
}

MAD_TEST_MAIN("RptqDocumentSectionEnumeratorTests",
	MAD_TEST(testInitReadsTheMainQueryAndStartsAtZero),
	MAD_TEST(testNextObjectIsPostIncrementSoRowZeroComesOutFirst),
	MAD_TEST(testAllObjectsReturnsEverySectionInRowOrder),
	MAD_TEST(testCountAddsTwoRowsPerGroup),
	MAD_TEST(testNextObjectIgnoresTheCountWhenThereIsNoQuery),
	MAD_TEST(testTypeEnumeratorAllObjectsListsTheSkeletonRowTypes),
	MAD_TEST(testTypeEnumeratorNextObjectSkipsRowZeroAndHasNoEnd));
