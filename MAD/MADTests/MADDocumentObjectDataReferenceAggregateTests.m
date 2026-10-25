//
//  MADDocumentObjectDataReferenceAggregateTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReferenceAggregate: the handle over
//  an aggregate element.  Pinned here: the element's group/function settings are surfaced
//  verbatim, -calculateInMemory is YES for exactly First and Last, -fieldKey qualifies the
//  aggregate field through its query-table alias, and the fieldKey is nil at every step of
//  the chain that has not been wired yet (no aggregate field, no datasource).
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
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElement+Extras.h"

// The smallest datasource the reference actually asks questions of: `database` only.
@interface MADDataReferenceAggregateDatasourceDouble : NSObject <MADPrintPageRendererDataSourceProtocol>
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@end

@implementation MADDataReferenceAggregateDatasourceDouble

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

@interface MADDocumentObjectDataReferenceAggregateTests : XCTestCase
@end

@implementation MADDocumentObjectDataReferenceAggregateTests

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

- (RptqDocumentElementAggregate *)aggregateElementInContext:(RptqStoreContext *)context field:(RptqQueryField *)field {
	RptqDocumentElementAggregate *element = (RptqDocumentElementAggregate *)[context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	element.type = MADPrintPageElementTypeAggregate;
	element.aggregateField = field;
	return element;
}

- (MADDocumentObjectDataReferenceAggregate *)referenceForElement:(RptqDocumentElementAggregate *)element
														datasource:(id <MADPrintPageRendererDataSourceProtocol>)datasource {
	return (MADDocumentObjectDataReferenceAggregate *)[MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																											 delegate:nil
																												 page:2
																												 item:element
																											   itemID:11];
}

#pragma mark - Tests

- (void)testFactoryReturnsAggregateReference {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:nil];

	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:nil];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceAggregate");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeAggregate);
}

- (void)testGroupAndFunctionSettingsAreSurfacedFromTheElement {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:nil];
	element.groupNumber = 5;
	element.groupType = MTAggregateGroupByTypeSection;
	element.functionType = MTAggregateFunctionTypeSum;
	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:nil];

	XCTAssertEqual(reference.groupNumber, 5);
	XCTAssertEqual(reference.groupType, MTAggregateGroupByTypeSection);
	XCTAssertEqual(reference.functionType, MTAggregateFunctionTypeSum);
}

- (void)testCalculateInMemoryIsTrueForFirstAndLastOnly {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:nil];
	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:nil];

	NSArray<NSNumber *> *inMemory = @[ @(MTAggregateFunctionTypeFirst), @(MTAggregateFunctionTypeLast) ];
	NSArray<NSNumber *> *streamed = @[ @(MTAggregateFunctionTypeSum),
									   @(MTAggregateFunctionTypeMean),
									   @(MTAggregateFunctionTypeCount),
									   @(MTAggregateFunctionTypeMin),
									   @(MTAggregateFunctionTypeMax),
									   @(MTAggregateFunctionTypeUnknown),
									   @(MTAggregateFunctionTypeNotSet) ];

	for (NSNumber *function in inMemory) {
		element.functionType = (MTAggregateFunctionType)function.intValue;
		XCTAssertTrue(reference.calculateInMemory, @"%@ should be calculated in memory", function);
	}
	for (NSNumber *function in streamed) {
		element.functionType = (MTAggregateFunctionType)function.intValue;
		XCTAssertFalse(reference.calculateInMemory, @"%@ should be read from the cache", function);
	}
}

- (void)testFieldKeyQualifiesTheAggregateFieldWithTheTableAlias {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Total" tableName:@"Invoice" context:context document:document];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:field];
	MADDataReferenceAggregateDatasourceDouble *datasource = [[MADDataReferenceAggregateDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:datasource];

	XCTAssertEqualObjects(reference.fieldKey, @"Invoice0.Total");
}

- (void)testFieldKeyIsNilWithoutAnAggregateField {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:nil];
	MADDataReferenceAggregateDatasourceDouble *datasource = [[MADDataReferenceAggregateDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:datasource];

	XCTAssertNil(reference.fieldKey);
}

- (void)testFieldKeyIsNilWithoutADatasource {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Total" tableName:@"Invoice" context:context document:document];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:field];

	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:nil];

	XCTAssertNil(reference.fieldKey);
}

- (void)testFormattedStringUsesTheAggregateFieldType {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Total" tableName:@"Invoice" context:context document:document];
	RptqDocumentElementAggregate *element = [self aggregateElementInContext:context field:field];
	MADDocumentObjectDataReferenceAggregate *reference = [self referenceForElement:element datasource:nil];

	NSString *formatted = [reference formattedStringForValue:@"abc"];
	XCTAssertEqualObjects(formatted, @"abc");
}

@end
