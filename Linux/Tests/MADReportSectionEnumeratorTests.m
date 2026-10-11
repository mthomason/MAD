//
//  MADReportSectionEnumeratorTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADReportSectionEnumeratorTests.m: fast enumeration
//  over the sections of a document, one MADReportSection per report row.  With no
//  query groups the sequence is the five skeleton sections; with a group it is
//  the same with the group's header before the detail and its footer after.  An
//  enumerator with no query yields nothing.  The Xcode suite's in-memory Core
//  Data context is a real SQLite store under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/MADReportSectionEnumerator.h>
#import <MAD/MADReportSection.h>
#import <MAD/MADStore.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>

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

static NSArray<MADReportSection *> *sectionsFromEnumerator(MADReportSectionEnumerator *enumerator) {
	NSMutableArray<MADReportSection *> *sections = [NSMutableArray array];
	for (MADReportSection *section in enumerator) {
		[sections addObject:section];
	}
	return sections;
}

#pragma mark - Tests

static void testEnumeratorKeepsTheQuery(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);

	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] initWithQuery:document.mainQuery];

	MAD_PASS(enumerator.query == document.mainQuery, "the enumerator keeps the query");

	[enumerator release];
}

static void testFiveSkeletonSectionsWithoutGroups(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);

	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] initWithQuery:document.mainQuery];
	NSArray<MADReportSection *> *sections = sectionsFromEnumerator(enumerator);

	MAD_PASS(sections.count == (NSUInteger)5, "five skeleton sections without groups");
	MAD_PASS(sections[0].type == MADDocumentSectionTypeReportHeader, "row 0 is the report header");
	MAD_PASS(sections[1].type == MADDocumentSectionTypePageHeader, "row 1 is the page header");
	MAD_PASS(sections[2].type == MADDocumentSectionTypeBody, "row 2 is the body");
	MAD_PASS(sections[3].type == MADDocumentSectionTypePageFooter, "row 3 is the page footer");
	MAD_PASS(sections[4].type == MADDocumentSectionTypeReportFooter, "row 4 is the report footer");

	[enumerator release];
}

static void testGroupSectionsWrapTheBody(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQuery *query = document.mainQuery;

	// A group with both its sections, wired the way MADocument builds one.
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:MADSortOrderAccending
													andManagedObjectContext:context];
	[query addHasQueryGroupsObject:group];
	RptqDocumentSection *groupHeader = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupHeader
															 forManagedObjectContext:context];
	RptqDocumentSection *groupFooter = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupFooter
															 forManagedObjectContext:context];
	[group addHasSectionObject:groupHeader];
	[group addHasSectionObject:groupFooter];

	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] initWithQuery:query];
	NSArray<MADReportSection *> *sections = sectionsFromEnumerator(enumerator);

	MAD_PASS(sections.count == (NSUInteger)7, "a group adds its two sections");
	MAD_PASS(sections[0].type == MADDocumentSectionTypeReportHeader, "row 0 is the report header");
	MAD_PASS(sections[1].type == MADDocumentSectionTypePageHeader, "row 1 is the page header");
	MAD_PASS(sections[2].type == MADDocumentSectionTypeGroupHeader, "row 2 is the group header");
	MAD_PASS(sections[3].type == MADDocumentSectionTypeBody, "row 3 is the body");
	MAD_PASS(sections[4].type == MADDocumentSectionTypeGroupFooter, "row 4 is the group footer");
	MAD_PASS(sections[5].type == MADDocumentSectionTypePageFooter, "row 5 is the page footer");
	MAD_PASS(sections[6].type == MADDocumentSectionTypeReportFooter, "row 6 is the report footer");

	[enumerator release];
}

static void testEnumeratorWithoutAQueryYieldsNothing(void) {
	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] init];

	NSArray<MADReportSection *> *sections = sectionsFromEnumerator(enumerator);

	MAD_PASS(enumerator.query == nil, "a default enumerator has no query");
	MAD_PASS(sections.count == (NSUInteger)0, "an enumerator without a query yields nothing");

	[enumerator release];
}

MAD_TEST_MAIN("MADReportSectionEnumeratorTests",
	MAD_TEST(testEnumeratorKeepsTheQuery),
	MAD_TEST(testFiveSkeletonSectionsWithoutGroups),
	MAD_TEST(testGroupSectionsWrapTheBody),
	MAD_TEST(testEnumeratorWithoutAQueryYieldsNothing));
