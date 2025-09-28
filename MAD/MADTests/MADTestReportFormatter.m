






/*

#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import <MADFoundation/MADFoundation.h>
#import <MADAPI/MADAPI.h>
#import <MAD/MAD.h>

// Class Headers for Protocols
#import "MADReportFormatterDataSourceProtocol.h"
//#import "MADCacheProtocol.h"

// Class Headers for Implementation
#import "MADReportFormatter.h"
//#import "MADDataTableVirtual.h"
//#import "MADDataColumn.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQuerySort.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
//#import "MADDatabaseField.h"
#import "MADSectionRepresentation.h"
#import "MADSectionsLayout.h"
#import <MADSqlite3/MADArrayCaching.h>
#import "MADDocumentObjectType.h"
#import "MADMock.h"

@interface TestMADReportFormatter : XCTestCase <MADReportFormatterDataSource, MADCacheProtocol>

@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) MADDataTableVirtual *testDataTable;
@property (nonatomic, strong) RptqDocument *testDocument;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

@end

@implementation TestMADReportFormatter

- (void)setUp {
	[super setUp];
	
	// 1. Set up in-memory Core Data stack
	NSBundle *bundle = [NSBundle bundleForClass:[RptqDocument class]];
	NSURL *modelURL = [bundle URLForResource:@"MAD" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
	self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	self.moc.persistentStoreCoordinator = psc;
	
	// 2. Create Mock Data Table
	self.testDataTable = [[MADDataTableVirtual alloc] initWithId:1];
	MADDataColumn *groupCol = [MADDataColumn newDataColumnWithIdentifier:@"group"];
	groupCol.type = MADDataTypeString;
	MADDataColumn *valueCol = [MADDataColumn newDataColumnWithIdentifier:@"value"];
	valueCol.type = MADDataTypeInteger;
	[self.testDataTable addColumn:groupCol];
	[self.testDataTable addColumn:valueCol];
	
	// Group A
	[self.testDataTable addRowWithDataForFieldKeys:@{@"group": @"Group A", @"value": @1}];
	[self.testDataTable addRowWithDataForFieldKeys:@{@"group": @"Group A", @"value": @2}];
	[self.testDataTable addRowWithDataForFieldKeys:@{@"group": @"Group A", @"value": @3}];
	// Group B
	[self.testDataTable addRowWithDataForFieldKeys:@{@"group": @"Group B", @"value": @4}];
	[self.testDataTable addRowWithDataForFieldKeys:@{@"group": @"Group B", @"value": @5}];
	
	// 3. Create Mock Document & Layout
	self.testDocument = [RptqDocument newDocumentForManagedObjectContext:self.moc];
	
	// Create Schema and Query Field for Sorting
	MADDatabaseField *dbField = [[MADDatabaseField alloc] initWithName:@"group"];
	dbField.fieldType = MADDataTypeString;
	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:self.moc andField:dbField];
	RptqQueryField *queryField = [RptqQueryField newQueryField:self.moc];
	queryField.databaseSchemaField = schemaField;
	
	// Create Sort Object
	RptqQuerySort *sort = [NSEntityDescription insertNewObjectForEntityForName:@"RptqQuerySort" inManagedObjectContext:self.moc];
	sort.hasField = queryField;
	sort.ascending = YES;
	
	// Assign sort to query
	RptqQuery *query = self.testDocument.mainQuery;
	query.hasQuerySort = sort;
	
	RptqDocumentSection *groupFooter = [self.testDocument documentSectionForType:MADDocumentSectionTypeGroupFooter andLevel:0];
	
	RptqDocumentSectionRows *row = [NSEntityDescription insertNewObjectForEntityForName:@"RptqDocumentSectionRows" inManagedObjectContext:self.moc];
	RptqDocumentElementAggregate *element = [NSEntityDescription insertNewObjectForEntityForName:@"RptqDocumentElementAggregate" inManagedObjectContext:self.moc];
	element.type = MADPrintPageElementTypeAggregate;
	
	[row addHasObjectsObject:element];
	[groupFooter addHasRowsObject:row];
	
	// 4. Setup the Report Formatter
	self.reportFormatter = [[MADReportFormatter alloc] initWithDocument:(MADocument*)self.testDocument options:MADReportFormatterOptionsNone];
	self.reportFormatter.datasource = self;
	self.reportFormatter.cachedDelegate = self;
}

- (void)tearDown {
	self.moc = nil;
	self.testDataTable = nil;
	self.testDocument = nil;
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

*/
