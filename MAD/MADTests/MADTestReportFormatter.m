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

#pragma mark - Test double

// MADReportFormatter takes a MADocument -- a UIManagedDocument -- and reads exactly four
// things from it: -filename, the class of -database, -managedObjectContext, and
// -resetSectionLayoutManagers.  It cannot be opened for real here: -openWithCompletionHandler:
// goes through MADocument -readFromURL:error:, which unarchives a .mad produced by the app's
// create path, and there is no such archive to hand it.  So this double answers those four
// from the in-memory stack the test builds.  The original test cast a plain RptqDocument to
// MADocument *, which is not a MADocument at all -- hence the unrecognized -filename.
@interface MADTestReportFormatterDocument : MADocument

@property (nonatomic, strong) NSManagedObjectContext *testManagedObjectContext;
@property (nonatomic, strong) RptqDocument *testActiveDocumentModel;

@end

@implementation MADTestReportFormatterDocument

- (NSManagedObjectContext *)managedObjectContext { return self.testManagedObjectContext; }
- (RptqDocument *)activeDocumentModel { return self.testActiveDocumentModel; }

// The base implementation builds a real MADDatabase from the document's schemas; this test
// document has none.  Only the *class* is read, by MADSectionsLayout, which uses it for the
// identifier-quoting closure: with no class it hands back identifiers untouched, so the
// group sort key the fixture builds is the unquoted "alias.field".
- (MADDatabase *)database { return nil; }

- (NSString *)filename { return @"MADTestReportFormatter"; }

@end

@interface TestMADReportFormatter : XCTestCase <MADReportFormatterDataSource, MADCacheProtocol>

@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) MADDataTableVirtual *testDataTable;
@property (nonatomic, strong) RptqDocument *testDocument;
@property (nonatomic, strong) MADTestReportFormatterDocument *document;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

@end

@implementation TestMADReportFormatter

- (void)setUp {
	[super setUp];

	// 1. Set up in-memory Core Data stack.
	// The test bundle, not the framework's: MAD.xcdatamodeld is compiled into this
	// target's Sources phase, so MAD.momd lives here and nowhere else.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *modelURL = [bundle URLForResource:@"MAD" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];

	// Two contexts, the way MADocument has them: UIManagedDocument's is a child of the
	// store's.  That layering is not cosmetic here -- every Rptq class assigns its
	// required `identifier` from -awakeFromInsert, and that override is guarded by
	// `self.managedObjectContext.parentContext`, so a flat context leaves every new
	// object with a nil identifier and the save fails validation.
	NSManagedObjectContext *parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	parentContext.persistentStoreCoordinator = psc;

	self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	self.moc.parentContext = parentContext;

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
	NSString *tableAlias = [RptqQueryTable queryAliasForSchemaTableName:queryTable.alias
															  dropIndex:queryTable.dropIndex];
	NSString *sortKey = [[tableAlias stringByAppendingString:@"."] stringByAppendingString:schemaField.name];

	// Group A
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @1, MADIdentifierROWID: @1}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @2, MADIdentifierROWID: @2}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group A", @"value": @3, MADIdentifierROWID: @3}];
	// Group B
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group B", @"value": @4, MADIdentifierROWID: @4}];
	[self.testDataTable addRowWithDataForFieldKeys:@{sortKey: @"Group B", @"value": @5, MADIdentifierROWID: @5}];

	// Create Sort Object
	RptqQuerySort *sort = [NSEntityDescription insertNewObjectForEntityForName:@"RptqQuerySort" inManagedObjectContext:self.moc];
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

	RptqDocumentElementAggregate *element = [NSEntityDescription insertNewObjectForEntityForName:@"RptqDocumentElementAggregate" inManagedObjectContext:self.moc];
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
	XCTAssertTrue([self.moc.parentContext save:&saveError], @"Could not save the store context: %@", saveError);

	// 4. Setup the Report Formatter
	NSURL *url = [NSURL fileURLWithPath:
				  [NSTemporaryDirectory() stringByAppendingPathComponent:@"MADTestReportFormatter.mad"]];
	self.document = [[MADTestReportFormatterDocument alloc] initWithFileURL:url];
	self.document.testManagedObjectContext = self.moc;
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
	NSString *tempDir = NSTemporaryDirectory();
	return [NSURL fileURLWithPath:tempDir isDirectory:YES];
}

@end
