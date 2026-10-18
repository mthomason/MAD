//
//  MADTestReportFormatter.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Group-footer row-ID association: the footer for a group has to be associated
//  with the *last* row of that group, which is what tells the printer which rows
//  it is totalling.  Runs against an in-memory Core Data stack and an in-memory
//  MADDataTableVirtual, so it needs neither a document on disk nor a database --
//  the MADocument MADReportFormatter wants is stood in for by a test double.
//
//  The fixture has to reach the formatter's own thresholds to mean anything: the
//  sections must be in the store, since MADSectionsLayout fetches them as
//  dictionaries; the group must hang off the query, since that is how
//  -documentSectionForType:andLevel: finds its footer; and the rows must carry the
//  cache's key and row id.  Each of those is commented where it is built.
//

#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import <MADFoundation/MADFoundation.h>
#import <MADAPI/MADAPI.h>
#import <MAD/MAD.h>

// Class Headers for Protocols
#import "MADReportFormatterDataSourceProtocol.h"

// Class Headers for Implementation
#import "MADReportFormatter.h"
#import "MADSectionRepresentation.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQuerySort.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "MADDocumentObjectType.h"
// reportLayout is a MADArrayCaching, forward-declared by MADReportFormatter.h, so
// counting it and subscripting it needs the real interface.
#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDataTableFast.h>

#pragma mark - Test double

// MADReportFormatter takes whatever conforms to MADDocumentRenderProtocol and reads
// exactly four things from it: -filename, the class of -database, -storeContext, and
// -resetSectionLayoutManagers.  It cannot be opened for real here: -openWithCompletionHandler:
// goes through MADocument -readFromURL:error:, which unarchives a .mad produced by the app's
// create path, and there is no such archive to hand it.  So this double answers those four
// from the in-memory stack the test builds.  The original test cast a plain RptqDocument to
// MADocument *, which is not a MADocument at all -- hence the unrecognized -filename.
@interface MADTestReportFormatterDocument : MADocument

@property (nonatomic, strong) RptqStoreContext *testStoreContext;
@property (nonatomic, strong) RptqDocument *testActiveDocumentModel;

@end

@interface MADTestReportFormatterDocument ()

// The readwrite side of MADDocument's dataTable, which the render protocol
// exposes readonly: lets a test stand a real row table in for the cache the
// formatter consults for a group level's type.
@property (nonatomic, readwrite, strong) MADDataTableFast *dataTable;

@end

@implementation MADTestReportFormatterDocument

- (RptqStoreContext *)storeContext { return self.testStoreContext; }
- (RptqDocument *)activeDocumentModel { return self.testActiveDocumentModel; }

// The base implementation builds a real MADDatabase from the document's schemas; this test
// document has none.  Only the *class* is read, by MADSectionsLayout, which uses it for the
// identifier-quoting closure: with no class it hands back identifiers untouched, so the
// group sort key the fixture builds is the unquoted "alias.field".
- (MADDatabase *)database { return nil; }

- (NSString *)filename { return @"MADTestReportFormatter"; }

@end

@interface TestMADReportFormatter : XCTestCase <MADReportFormatterDataSource, MADCacheProtocol>

@property (nonatomic, copy) NSString *testDirectory;
@property (nonatomic, strong) RptqStoreContext *moc;
@property (nonatomic, strong) MADDataTableVirtual *testDataTable;
@property (nonatomic, strong) RptqDocument *testDocument;
@property (nonatomic, strong) RptqQueryField *testQueryField;
@property (nonatomic, strong) RptqQueryGroup *testGroup;
@property (nonatomic, strong) MADTestReportFormatterDocument *document;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

@end

@implementation TestMADReportFormatter

- (void)setUp {
	[super setUp];

	// 1. Set up a store-backed context.  The directory is per test and is also
	// the formatter's cache directory: every formatter in this class shares the
	// same filename, so a shared directory would make one test's cache database
	// (and any transaction left open by a throwing format) visible to the next.
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	self.testDirectory = directory;
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:storeURL];
	XCTAssertTrue([store openWithError:NULL], @"open failed");
	self.moc = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([self.moc loadAllWithError:NULL], @"load failed");

	// 2. Create Mock Data Table
	self.testDataTable = [[MADDataTableVirtual alloc] initWithId:1];
	MADDataColumn *groupCol = [MADDataColumn newDataColumnWithIdentifier:@"group"];
	groupCol.type = MADDataTypeString;
	MADDataColumn *valueCol = [MADDataColumn newDataColumnWithIdentifier:@"value"];
	valueCol.type = MADDataTypeInteger;
	[self.testDataTable addColumn:groupCol];
	[self.testDataTable addColumn:valueCol];

	// 3. Create Mock Document & Layout
	self.testDocument = [RptqDocument newDocumentForManagedObjectContext:self.moc];

	// Create Schema and Query Field for Sorting.  The field has to hang off a table that
	// the query actually selects: MADSectionGroupLayout reads the group's
	// sort/weight/dataType and, through the field, its table alias and drop index, and
	// hands each to CFNumberGetValue / -copy without a nil check -- an unwired field
	// dereferences NULL.  See BUGS.md.
	MADDatabaseField *dbField = [[MADDatabaseField alloc] initWithName:@"group"];
	dbField.fieldType = MADDataTypeString;
	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:self.moc andField:dbField];

	RptqDatabaseSchemaTable *schemaTable;
	schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:self.moc
																						   name:@"group"
																				   andQueryable:YES];
	[self.testDocument.defaultDatabase addHasTablesObject:schemaTable];
	schemaField.inTable = schemaTable;

	RptqQueryTable *queryTable;
	queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
												   database:self.testDocument.defaultDatabase
									 forManagedObjectContext:self.moc];

	RptqQueryField *queryField = [RptqQueryField newQueryField:self.moc];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	self.testQueryField = queryField;

	// The report data has to look like what the cache hands back, in two ways the
	// formatter relies on and reads without guarding:
	//   * the group value is keyed by the group's sort key, which
	//     MADSectionGroupLayout -safeSortKey builds by taking the table alias, running it
	//     back through +queryAliasForSchemaTableName:dropIndex: (which appends the drop
	//     index, so "group" becomes "group0"), and appending the field name.  A row keyed
	//     by the bare field name reads back as nil, every row then compares equal, and
	//     the whole report collapses into one group.
	//   * each row carries MADIdentifierROWID, which the sqlite-backed tables inject in
	//     their enumerators (MADDataTableObjectEnumerator.m:165).  Without it every row
	//     reports row id 0.
	NSString *sortKey = [self groupSortKey];

	// Group A
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @1, MADIdentifierROWID: @1}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @2, MADIdentifierROWID: @2}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @3, MADIdentifierROWID: @3}];
	// Group B
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group B", @"value": @4, MADIdentifierROWID: @4}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group B", @"value": @5, MADIdentifierROWID: @5}];

	// Create Sort Object
	RptqQuerySort *sort = [self.moc insertObjectForEntity:@"RptqQuerySort" identifier:0];
	sort.hasField = queryField;
	sort.ascending = YES;

	// Assign sort to query
	RptqQuery *query = self.testDocument.mainQuery;
	query.hasQuerySort = sort;

	// A group footer has no independent existence: -documentSectionForType:andLevel:
	// resolves it through the RptqQueryGroup at that level and answers nil when the query
	// has no such group, so an unwired footer is silently dropped and the formatter emits
	// nothing to assert against.  Build the group the way MADocument
	// -addQueryGroupWithQueryField:andSortOrder: does, header and footer sections included.
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:MADSortOrderAccending
												   andManagedObjectContext:self.moc];
	group.hasField = queryField;
	self.testGroup = group;
	[query addHasQueryGroupsObject:group];

	// A section's -hasRows is required and must not be empty, so each gets a row.
	RptqDocumentSection *groupHeader = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupHeader
														   forManagedObjectContext:self.moc];
	RptqDocumentSectionRows *headerRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:self.moc];
	headerRow.inSection = groupHeader;
	groupHeader.hasRows = [[NSOrderedSet alloc] initWithObject:headerRow];

	RptqDocumentSection *groupFooter = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupFooter
														   forManagedObjectContext:self.moc];
	RptqDocumentSectionRows *row = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:self.moc];
	row.inSection = groupFooter;

	RptqDocumentElementAggregate *element = [self.moc insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	element.type = MADPrintPageElementTypeAggregate;
	[row addHasObjectsObject:element];

	groupFooter.hasRows = [[NSOrderedSet alloc] initWithObject:row];

	[group addHasSectionObject:groupHeader];
	[group addHasSectionObject:groupFooter];

	// Save before formatting, at both levels.  MADSectionsLayout reads the sections through
	// an NSDictionaryResultType fetch, which the store answers directly and which therefore
	// never sees unsaved inserts -- without this the layout builds with no sections at all.
	NSError *saveError = nil;
	XCTAssertTrue([self.moc save:&saveError], @"Could not save the test context: %@", saveError);

	// 4. Setup the Report Formatter
	NSURL *url = [NSURL fileURLWithPath:
				  [NSTemporaryDirectory() stringByAppendingPathComponent:@"MADTestReportFormatter.mad"]];
	self.document = [[MADTestReportFormatterDocument alloc] initWithFileURL:url];
	self.document.testStoreContext = self.moc;
	self.document.testActiveDocumentModel = self.testDocument;

	self.reportFormatter = [[MADReportFormatter alloc] initWithDocument:self.document options:MADReportFormatterOptionsNone];
	self.reportFormatter.datasource = self;
	self.reportFormatter.cachedDelegate = self;
}

- (void)tearDown {
	self.moc = nil;
	self.testDataTable = nil;
	self.testDocument = nil;
	self.document = nil;
	self.reportFormatter = nil;
	[super tearDown];
}

- (void)testGroupFooterRowIDAssociation {
	// 5. Run the formatter
	[self.reportFormatter format:CGSizeMake(800, 600)];

	// 6. Assert the results
	XCTAssertTrue(self.reportFormatter.reportLayout.count > 0, @"Report layout should have at least one page.");
	NSArray<MADSectionRepresentation*>* pageLayout = self.reportFormatter.reportLayout[0];

	__block MADSectionRepresentation *groupAFooter = nil;
	[pageLayout enumerateObjectsUsingBlock:^(MADSectionRepresentation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (obj.sectionType == MADDocumentSectionTypeGroupFooter && obj.groupLevel == 0) {
			groupAFooter = obj;
			*stop = YES;
		}
	}];

	XCTAssertNotNil(groupAFooter, @"Group A footer should be present in the report layout.");

	NSUInteger expectedRowIdForGroupAFooter = 3;
	XCTAssertEqual([groupAFooter detailRowId], expectedRowIdForGroupAFooter, @"The group footer for Group A should be associated with the last row of Group A (rowId 3).");
}

#pragma mark - Malformed groups

// A query group is a GROUP BY: it must name a field of a table the query selects.
// The report's group header/footer is only its presentation and may display no
// field at all -- the grouping still happens.  The add-group screen cannot create
// a group without a field, so a document that has one is malformed data.  The
// designer still builds and labels the layout (so the broken group can be seen);
// query execution and formatting refuse it when the field is used.  See BUGS.md.

- (void)saveTestContext {
	NSError *error = nil;
	XCTAssertTrue([self.moc save:&error], @"Could not save the test context: %@", error);
}

- (void)testGroupWithoutFieldRaisesWhenFormatted {
	self.testGroup.hasField = nil;
	[self saveTestContext];

	CGSize size = CGSizeMake(800, 600);
	XCTAssertThrowsSpecificNamed([self.reportFormatter format:size],
								 NSException, NSInvalidArgumentException,
								 @"The formatter must refuse a group with no grouping field.");
}

- (void)testGroupFieldWithoutQueryTableRaisesWhenFormatted {
	self.testQueryField.inQueryTable = nil;
	[self saveTestContext];

	CGSize size = CGSizeMake(800, 600);
	XCTAssertThrowsSpecificNamed([self.reportFormatter format:size],
								 NSException, NSInvalidArgumentException,
								 @"The formatter must refuse a group whose field is not in a selected table.");
}

- (void)testDesignerDisplayOfGroupWithoutFieldDoesNotThrow {
	self.testGroup.hasField = nil;
	[self saveTestContext];

	MADSectionsLayout *sections = [[MADSectionsLayout alloc] initWithManagedObjectContext:self.moc
																		   databaseClass:NULL];
	// MADSectionsLayout forward-declares MADSectionGroupLayout; the public
	// superclass carries -localizedDisplay, which is all this test reads.
	MADSectionLayout *header = (MADSectionLayout *)sections.groupHeaders.firstObject;
	XCTAssertNotNil(header, @"The header section should still be built for the designer to show.");

	XCTAssertNoThrow([header localizedDisplay]);
	NSString *display = [header localizedDisplay];
	XCTAssertTrue([display containsString:@"missing grouping field"],
				  @"The designer should label the broken group instead of crashing: %@", display);
}

// -newDocumentForManagedObjectContext: builds only the sections, not a database
// or query, so a test that needs the query path has to make the query itself.
- (RptqQuery *)queryContainingTestGroup {
	RptqQuery *query = (RptqQuery *)[self.moc insertObjectForEntity:NSStringFromClass([RptqQuery class])
														 identifier:0];
	[query addHasQueryGroupsObject:self.testGroup];
	XCTAssertEqual(query.hasQueryGroups.count, (NSUInteger)1,
				   @"The query must actually contain the group under test.");
	return query;
}

- (void)testQuerySortDescriptorsRejectGroupWithoutField {
	self.testGroup.hasField = nil;
	[self saveTestContext];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	RptqQuery *query = [self queryContainingTestGroup];

	XCTAssertThrowsSpecificNamed([query sortDescriptorsForDatabase:database],
								 NSException, NSInvalidArgumentException,
								 @"Query generation must refuse a group with no grouping field.");
}

- (void)testQuerySortDescriptorsRejectGroupFieldWithoutQueryTable {
	self.testQueryField.inQueryTable = nil;
	[self saveTestContext];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	RptqQuery *query = [self queryContainingTestGroup];

	XCTAssertThrowsSpecificNamed([query sortDescriptorsForDatabase:database],
								 NSException, NSInvalidArgumentException,
								 @"Query generation must refuse a field that is not in a selected table.");
}

#pragma mark - Group boundary behaviour

// The sort key the fixture rows are keyed by: the group's alias-qualified field
// name, built the way MADSectionGroupLayout -safeSortKey builds it.
- (NSString *)groupSortKey {
	RptqQueryTable *queryTable = self.testQueryField.inQueryTable;
	NSString *tableAlias = [RptqQueryTable queryAliasForSchemaTableName:queryTable.alias
																  dropIndex:queryTable.dropIndex];
	return [[tableAlias stringByAppendingString:@"."] stringByAppendingString:self.testQueryField.databaseSchemaField.name];
}

// Replaces the fixture rows with one row per value, in order; the value column
// and row id are filled in so the body still lays out.
- (void)setGroupValues:(NSArray <id> *)values {
	[self.testDataTable removeAllObjects];
	NSString *sortKey = [self groupSortKey];
	for (NSUInteger i = 0; i < values.count; i++) {
		[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: values[i], @"value": @(i + 1), MADIdentifierROWID: @(i + 1)}];
	}
}

- (NSUInteger)numberOfGroupHeadersInLayout {
	NSArray <MADSectionRepresentation *> *pageLayout = self.reportFormatter.reportLayout[0];
	NSUInteger count = 0;
	for (MADSectionRepresentation *section in pageLayout) {
		if (section.sectionType == MADDocumentSectionTypeGroupHeader) count++;
	}
	return count;
}

// Characterization: the string level compares case-insensitively, so two case
// variants of the same key are one group.
- (void)testCaseVariantStringValuesMergeIntoOneGroup {
	[self setGroupValues:@[@"Apple", @"apple"]];
	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)1);
}

// Characterization: NULL is first-class in the comparator, so NULL keys are one
// group and never compared with the typed path.
- (void)testNullGroupKeysFormOneGroup {
	[self setGroupValues:@[[NSNull null], [NSNull null]]];
	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)1);
}

- (void)testNullGroupKeysSplitFromRealValues {
	[self setGroupValues:@[[NSNull null], @"x"]];
	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)2);
}

// Characterization: the walks read only equality, so a descending group splits
// at the same boundaries an ascending one does.
- (void)testDescendingGroupSortStillGroupsByEquality {
	self.testGroup.sort = MADSortOrderDecending;
	[self saveTestContext];
	[self setGroupValues:@[@"A", @"A", @"B"]];
	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)2);
}

// Target: values outside the level's type are a contract violation -- a
// pre-contract cache can hold them -- so the formatter logs once and falls back
// to a safe class-checked comparison instead of raising.  (Pre-contract, the
// untyped -compare: dispatch raised an unrecognized selector here; the raise
// was pinned before the contract landed.)
- (void)testNumberValuesInAStringLevelUseTheColdFallback {
	[self setGroupValues:@[@1, @1, @2]];
	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)2);
}

// Target: the level's comparison type comes from the row cache's column, not the
// schema field.  The schema says String (case-insensitive), the cache column
// says Blob (bytewise), so "Apple" and "apple" are two groups.
- (void)testCacheColumnTypeBeatsTheSchemaType {
	[self setGroupValues:@[[@"Apple" dataUsingEncoding:NSUTF8StringEncoding],
						   [@"apple" dataUsingEncoding:NSUTF8StringEncoding]]];

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:99 cacheDirectory:[NSURL fileURLWithPath:self.testDirectory isDirectory:YES]];
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:[self groupSortKey]];
	column.fieldName = column.identifier;
	column.type = MADDataTypeBlob;
	[table addColumn:column];
	((MADTestReportFormatterDocument *)self.document).dataTable = table;

	[self.reportFormatter format:CGSizeMake(800, 600)];
	XCTAssertEqual([self numberOfGroupHeadersInLayout], (NSUInteger)2);
}

// Target: a class the cache reader can never produce is a genuine violation and
// asserts; a legacy cache's mismatches are only ever among the four classes the
// reader answers (NSNull, NSNumber, NSString, NSData).
- (void)testForeignValueClassesRaise {
	[self setGroupValues:@[[NSDate date], [NSDate date]]];
	XCTAssertThrowsSpecificNamed([self.reportFormatter format:CGSizeMake(800, 600)],
								 NSException, NSInternalInconsistencyException);
}

// Target: two levels, each compared under its own type -- level 0 a string
// (case-insensitive), level 1 a number.  The inner level's boundaries only
// matter inside one outer value, so (A,1),(A,1),(A,2),(B,1) is two outer groups
// and three inner ones.
- (void)testMultiLevelGroupsUseEachLevelsType {
	RptqQueryTable *queryTable = self.testQueryField.inQueryTable;

	MADDatabaseField *dbField = [[MADDatabaseField alloc] initWithName:@"region"];
	dbField.fieldType = MADDataTypeInteger;
	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:self.moc andField:dbField];
	RptqDatabaseSchemaTable *schemaTable = self.testQueryField.databaseSchemaField.inTable;
	schemaField.inTable = schemaTable;

	RptqQueryField *queryField = [RptqQueryField newQueryField:self.moc];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;

	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:MADSortOrderAccending
												   andManagedObjectContext:self.moc];
	group.weight = self.testGroup.weight + 1;
	group.hasField = queryField;
	[self.testDocument.mainQuery addHasQueryGroupsObject:group];

	RptqDocumentSection *groupHeader = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupHeader
															   forManagedObjectContext:self.moc];
	RptqDocumentSectionRows *headerRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:self.moc];
	headerRow.inSection = groupHeader;
	groupHeader.hasRows = [[NSOrderedSet alloc] initWithObject:headerRow];

	RptqDocumentSection *groupFooter = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupFooter
															   forManagedObjectContext:self.moc];
	RptqDocumentSectionRows *footerRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:self.moc];
	footerRow.inSection = groupFooter;
	groupFooter.hasRows = [[NSOrderedSet alloc] initWithObject:footerRow];
	[group addHasSectionObject:groupHeader];
	[group addHasSectionObject:groupFooter];
	[self saveTestContext];

	NSString *outerKey = [self groupSortKey];
	NSString *tableAlias = [RptqQueryTable queryAliasForSchemaTableName:queryTable.alias
																  dropIndex:queryTable.dropIndex];
	NSString *innerKey = [[tableAlias stringByAppendingString:@"."] stringByAppendingString:@"region"];
	[self.testDataTable removeAllObjects];
	NSArray *rows = @[@{outerKey: @"A", innerKey: @1, @"value": @1, MADIdentifierROWID: @1},
					  @{outerKey: @"A", innerKey: @1, @"value": @2, MADIdentifierROWID: @2},
					  @{outerKey: @"A", innerKey: @2, @"value": @3, MADIdentifierROWID: @3},
					  @{outerKey: @"B", innerKey: @1, @"value": @4, MADIdentifierROWID: @4}];
	for (NSDictionary *row in rows) {
		[self.testDataTable addRowWithDataForFieldKeys:row];
	}

	[self.reportFormatter format:CGSizeMake(800, 600)];

	NSArray <MADSectionRepresentation *> *pageLayout = self.reportFormatter.reportLayout[0];
	NSUInteger outerHeaders = 0, innerHeaders = 0;
	for (MADSectionRepresentation *section in pageLayout) {
		if (section.sectionType == MADDocumentSectionTypeGroupHeader) {
			if (section.groupLevel == 0) outerHeaders++;
			else if (section.groupLevel == 1) innerHeaders++;
		}
	}
	XCTAssertEqual(outerHeaders, (NSUInteger)2);
	XCTAssertEqual(innerHeaders, (NSUInteger)3);
}

#pragma mark - Level comparator

// The comparator the walks use, exercised directly: NULL first, then the typed
// comparison for the level's type, then the tolerated fallback for legacy pairs.

- (void)testComparatorHandlesNullFirstClass {
	XCTAssertEqual([MADReportFormatter compareValue:[NSNull null] withValue:[NSNull null] forDataType:MADDataTypeString], NSOrderedSame);
	XCTAssertEqual([MADReportFormatter compareValue:[NSNull null] withValue:@"x" forDataType:MADDataTypeString], NSOrderedAscending);
	XCTAssertEqual([MADReportFormatter compareValue:@"x" withValue:[NSNull null] forDataType:MADDataTypeString], NSOrderedDescending);
}

- (void)testComparatorUsesCaseInsensitiveStrings {
	XCTAssertEqual([MADReportFormatter compareValue:@"Apple" withValue:@"apple" forDataType:MADDataTypeString], NSOrderedSame);
	XCTAssertEqual([MADReportFormatter compareValue:@"apple" withValue:@"apricot" forDataType:MADDataTypeString], NSOrderedAscending);
}

- (void)testComparatorUsesNumericOrderForNumbers {
	XCTAssertEqual([MADReportFormatter compareValue:@2 withValue:@10 forDataType:MADDataTypeInteger], NSOrderedAscending);
	// The date family's canonical class is the epoch number.
	XCTAssertEqual([MADReportFormatter compareValue:@100.0 withValue:@200.0 forDataType:MADDataTypeDateTime], NSOrderedAscending);
}

- (void)testComparatorUsesByteOrderForData {
	NSData *a = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"b" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([MADReportFormatter compareValue:a withValue:b forDataType:MADDataTypeBlob], NSOrderedAscending);
	XCTAssertEqual([MADReportFormatter compareValue:a withValue:a forDataType:MADDataTypeBlob], NSOrderedSame);
}

- (void)testComparatorToleratesLegacyNumberValuesInAStringLevel {
	// A pre-contract cache can hold numbers in a text column; the pair still
	// orders instead of raising.
	XCTAssertEqual([MADReportFormatter compareValue:@1 withValue:@2 forDataType:MADDataTypeString], NSOrderedAscending);
}

- (void)testComparatorToleratesLegacyStringValuesInABlobLevel {
	XCTAssertEqual([MADReportFormatter compareValue:@"a" withValue:@"b" forDataType:MADDataTypeBlob], NSOrderedAscending);
}

- (void)testComparatorOrdersMixedClassPairsByClass {
	// A heterogeneous legacy column still groups homogeneous runs: a mixed
	// pair must not answer Same, or every row would collapse into one group.
	NSData *data = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([MADReportFormatter compareValue:@"x" withValue:data forDataType:MADDataTypeBlob], NSOrderedAscending);
	XCTAssertEqual([MADReportFormatter compareValue:data withValue:@"x" forDataType:MADDataTypeBlob], NSOrderedDescending);
	XCTAssertEqual([MADReportFormatter compareValue:@1 withValue:@"x" forDataType:MADDataTypeString], NSOrderedAscending);
}

- (void)testComparatorRaisesForClassesTheReaderCannotProduce {
	XCTAssertThrowsSpecificNamed([MADReportFormatter compareValue:[NSDate date] withValue:[NSDate date] forDataType:MADDataTypeString],
								 NSException, NSInternalInconsistencyException);
}

#pragma mark - MADReportFormatterDataSource

- (NSEnumerator *)enumeratorForReportData {
	return [self.testDataTable objectEnumerator];
}

- (BOOL)cacheExist {
	return NO;
}

- (NSDictionary *)dataForRow:(NSUInteger)cachedID {
	return [self.testDataTable dataForRow:cachedID error:nil];
}

- (NSUInteger)numberOfRows {
	return [self.testDataTable numberOfRows];
}

#pragma mark - MADCacheProtocol

- (NSURL *)cachedFilesDirectory {
	return [NSURL fileURLWithPath:self.testDirectory isDirectory:YES];
}

@end
