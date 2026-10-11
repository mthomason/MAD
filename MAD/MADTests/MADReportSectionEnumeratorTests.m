//
//  MADReportSectionEnumeratorTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADReportSectionEnumerator: fast enumeration over the
//  sections of a document, one MADReportSection per report row.  With no query groups the
//  sequence is the five skeleton sections (report header, page header, detail, page
//  footer, report footer); with a group it is the same with the group's header before the
//  detail and its footer after, so the row order matches MADDocumentSectionType's row
//  mapping.  An enumerator with no query yields nothing.
//

#import <XCTest/XCTest.h>

#import "MADReportSectionEnumerator.h"
#import "MADReportSection.h"
#import "MADStore.h"
#import "MADSortOrder.h"
#import "MADocumentSectionType.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

@interface MADReportSectionEnumeratorTests : XCTestCase
@end

@implementation MADReportSectionEnumeratorTests

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

- (NSArray<MADReportSection *> *)sectionsFromEnumerator:(MADReportSectionEnumerator *)enumerator {
	NSMutableArray<MADReportSection *> *sections = [NSMutableArray array];
	for (MADReportSection *section in enumerator) {
		[sections addObject:section];
	}
	return sections;
}

#pragma mark - Tests

- (void)testEnumeratorKeepsTheQuery {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];

	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] initWithQuery:document.mainQuery];

	XCTAssertEqual(enumerator.query, document.mainQuery);
}

- (void)testFiveSkeletonSectionsWithoutGroups {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];

	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] initWithQuery:document.mainQuery];
	NSArray<MADReportSection *> *sections = [self sectionsFromEnumerator:enumerator];

	XCTAssertEqual(sections.count, (NSUInteger)5);
	XCTAssertEqual(sections[0].type, MADDocumentSectionTypeReportHeader);
	XCTAssertEqual(sections[1].type, MADDocumentSectionTypePageHeader);
	XCTAssertEqual(sections[2].type, MADDocumentSectionTypeBody);
	XCTAssertEqual(sections[3].type, MADDocumentSectionTypePageFooter);
	XCTAssertEqual(sections[4].type, MADDocumentSectionTypeReportFooter);
}

- (void)testGroupSectionsWrapTheBody {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
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
	NSArray<MADReportSection *> *sections = [self sectionsFromEnumerator:enumerator];

	XCTAssertEqual(sections.count, (NSUInteger)7);
	XCTAssertEqual(sections[0].type, MADDocumentSectionTypeReportHeader);
	XCTAssertEqual(sections[1].type, MADDocumentSectionTypePageHeader);
	XCTAssertEqual(sections[2].type, MADDocumentSectionTypeGroupHeader);
	XCTAssertEqual(sections[3].type, MADDocumentSectionTypeBody);
	XCTAssertEqual(sections[4].type, MADDocumentSectionTypeGroupFooter);
	XCTAssertEqual(sections[5].type, MADDocumentSectionTypePageFooter);
	XCTAssertEqual(sections[6].type, MADDocumentSectionTypeReportFooter);
}

- (void)testEnumeratorWithoutAQueryYieldsNothing {
	MADReportSectionEnumerator *enumerator = [[MADReportSectionEnumerator alloc] init];

	NSArray<MADReportSection *> *sections = [self sectionsFromEnumerator:enumerator];

	XCTAssertNil(enumerator.query);
	XCTAssertEqual(sections.count, (NSUInteger)0);
}

@end
