//
//  MADDocumentObjectDataReferenceLabelDynamicTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReferenceLabelDynamic: the handle
//  over a data label.  Its fieldKey is the qualified name built from the referenced query
//  field's table alias and schema field name via the datasource's database; its
//  formattedStringForValue: reads the value using the schema field's data type.
//
//  The datasource is consulted through its `database` property only, so the double below
//  returns a MADMock database (queryKey:table: -> "<table>.<field>") and empty answers
//  for everything else.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADDocumentObjectDataReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADMock.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElement+Extras.h"

// The smallest datasource the reference actually asks questions of: `database` only.
@interface MADDataReferenceLabelDynamicDatasourceDouble : NSObject <MADPrintPageRendererDataSourceProtocol>
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@end

@implementation MADDataReferenceLabelDynamicDatasourceDouble

- (NSArray<MADResult *> *)groupLevelKeys:(__unused int64_t)rowID { return @[]; }
- (NSArray<MADResult *> *)groupKeys:(__unused int64_t)rowID groupNumber:(__unused int64_t)groupNumber { return @[]; }
- (NSArray<NSString *> *)groupLevelKeyNames { return @[]; }

- (NSDictionary<NSString *, MADResult *> *)dataForRow:(__unused NSUInteger)rowID
												error:(__unused NSError * __autoreleasing *)error { return nil; }
- (NSDictionary *)dataForRowReportFirst { return nil; }
- (NSDictionary *)dataForRowReportLast { return nil; }
- (NSDictionary *)dataForRowPageFirst:(__unused NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRowPageLast:(__unused NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRow:(__unused NSUInteger)rowID
					  column:(__unused NSString *)columnKey
					   error:(__unused NSError * __autoreleasing *)error { return nil; }
- (NSArray<__kindof NSDictionary *> *)dataForGroups:(__unused NSArray *)groupKeys
											groupID:(__unused int64_t)groupID { return @[]; }
- (__kindof NSObject<NSCopying> *)dataForRows:(__unused NSArray *)rowIDs
									   column:(__unused NSString *)columnKey
									   groups:(__unused NSArray *)groupKeys
									 function:(__unused MTAggregateFunctionType)function
									  groupBy:(__unused MTAggregateGroupByType)groupBy { return nil; }
- (NSUInteger)rowIDFirstOfReport { return 0; }
- (NSUInteger)rowIDLastOfReport { return 0; }
- (NSUInteger)rowIDFirstOfPage:(__unused NSUInteger)page { return 0; }
- (NSUInteger)rowIDLastOfPage:(__unused NSUInteger)page { return 0; }
- (NSArray<NSNumber *> *)rowIDsForPage:(__unused NSUInteger)pageIndex { return @[]; }

- (void)updatePrintingReportFormatter { }

@end

@interface MADDocumentObjectDataReferenceLabelDynamicTests : XCTestCase
@end

@implementation MADDocumentObjectDataReferenceLabelDynamicTests

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

// A query field wired the way the document model expects: schema field -> schema
// table -> query table -> query field.
- (RptqQueryField *)queryFieldNamed:(NSString *)name
						   tableName:(NSString *)tableName
							 context:(RptqStoreContext *)context
							document:(RptqDocument *)document {

	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = MADDataTypeString;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	RptqDatabaseSchemaTable *schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																													name:tableName
																											andQueryable:YES];
	[document.defaultDatabase addHasTablesObject:schemaTable];
	schemaField.inTable = schemaTable;

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	database:document.defaultDatabase
													  forManagedObjectContext:context];

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	return queryField;
}

- (MADDocumentObjectDataReferenceLabelDynamic *)referenceForField:(RptqQueryField *)field
														   context:(RptqStoreContext *)context
														datasource:(id <MADPrintPageRendererDataSourceProtocol>)datasource {
	RptqDocumentElementLabelDataField *element = (RptqDocumentElementLabelDataField *)[context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	element.type = MADPrintPageElementTypeLabelDynamic;
	element.referencesQueryField = field;
	return (MADDocumentObjectDataReferenceLabelDynamic *)[MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																												delegate:nil
																													page:1
																													item:element
																												  itemID:7];
}

#pragma mark - Tests

- (void)testFactoryReturnsLabelDynamicReference {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];

	MADDocumentObjectDataReferenceLabelDynamic *reference = [self referenceForField:field context:context datasource:nil];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceLabelDynamic");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeLabelDynamic);
}

- (void)testFieldKeyQualifiesTheFieldWithTheTableAlias {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	MADDataReferenceLabelDynamicDatasourceDouble *datasource = [[MADDataReferenceLabelDynamicDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceLabelDynamic *reference = [self referenceForField:field context:context datasource:datasource];

	// The first table keeps dropIndex 0, so the alias is the table name plus "0".
	XCTAssertEqualObjects(reference.fieldKey, @"Invoice0.Name");
}

- (void)testFieldKeyIsNilWithoutADatasource {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];

	MADDocumentObjectDataReferenceLabelDynamic *reference = [self referenceForField:field context:context datasource:nil];

	XCTAssertNil(reference.fieldKey);
}

- (void)testFormattedStringUsesTheSchemaFieldType {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	MADDataReferenceLabelDynamicDatasourceDouble *datasource = [[MADDataReferenceLabelDynamicDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];
	MADDocumentObjectDataReferenceLabelDynamic *reference = [self referenceForField:field context:context datasource:datasource];

	NSString *formatted = [reference formattedStringForValue:@"abc"];
	XCTAssertEqualObjects(formatted, @"abc");
}

@end
