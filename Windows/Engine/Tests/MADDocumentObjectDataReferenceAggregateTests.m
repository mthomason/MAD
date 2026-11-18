//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentObjectDataReferenceAggregateTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceAggregateTests.m:
//  MADDocumentObjectDataReferenceAggregate, the handle over an aggregate
//  element.  The element's group/function settings are surfaced verbatim,
//  -calculateInMemory is YES for exactly First and Last, -fieldKey qualifies
//  the aggregate field through its query-table alias, and the fieldKey is nil
//  at every step of the chain that has not been wired yet (no aggregate field,
//  no datasource).
//
//  The datasource double answers only `database`, with a MADMock database
//  (queryKey:table: -> "<table>.<field>"); the mock is the portable half of
//  MADMock (Tests/Support/MADMock.h).  The store is a real SQLite file under a
//  per-test temp directory, as in the Xcode suite.
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADMock.h"
#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElement+Extras.h>

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

static RptqQueryField *queryFieldNamed(NSString *name, NSString *tableName,
									   RptqStoreContext *context, RptqDocument *document) {
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

static RptqDocumentElementAggregate *aggregateElementInContext(RptqStoreContext *context, RptqQueryField *field) {
	RptqDocumentElementAggregate *element = (RptqDocumentElementAggregate *)[context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	element.type = MADPrintPageElementTypeAggregate;
	element.aggregateField = field;
	return element;
}

static MADDocumentObjectDataReferenceAggregate *referenceForElement(RptqDocumentElementAggregate *element,
																	id <MADPrintPageRendererDataSourceProtocol> datasource) {
	return (MADDocumentObjectDataReferenceAggregate *)[MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																											delegate:nil
																												page:2
																												item:element
																											  itemID:11];
}

#pragma mark - Tests

static void testFactoryReturnsAggregateReference(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, nil);

	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, nil);

	MAD_PASS_EQUAL(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceAggregate",
				   "the factory returns the aggregate reference");
	MAD_PASS(reference.type == MADPrintPageElementTypeAggregate, "the reference reads the element's type");
}

static void testGroupAndFunctionSettingsAreSurfacedFromTheElement(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, nil);
	element.groupNumber = 5;
	element.groupType = MTAggregateGroupByTypeSection;
	element.functionType = MTAggregateFunctionTypeSum;
	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, nil);

	MAD_PASS(reference.groupNumber == 5, "the group number comes from the element");
	MAD_PASS(reference.groupType == MTAggregateGroupByTypeSection, "the group type comes from the element");
	MAD_PASS(reference.functionType == MTAggregateFunctionTypeSum, "the function type comes from the element");
}

static void testCalculateInMemoryIsTrueForFirstAndLastOnly(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, nil);
	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, nil);

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
		MAD_PASS(reference.calculateInMemory, "%s should be calculated in memory", function.stringValue.UTF8String);
	}
	for (NSNumber *function in streamed) {
		element.functionType = (MTAggregateFunctionType)function.intValue;
		MAD_PASS(!reference.calculateInMemory, "%s should be read from the cache", function.stringValue.UTF8String);
	}
}

static void testFieldKeyQualifiesTheAggregateFieldWithTheTableAlias(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Total", @"Invoice", context, document);
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, field);
	MADDataReferenceAggregateDatasourceDouble *datasource = [[MADDataReferenceAggregateDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, datasource);

	MAD_PASS_EQUAL(reference.fieldKey, @"Invoice0.Total", "the field key qualifies the aggregate field with the table alias");
}

static void testFieldKeyIsNilWithoutAnAggregateField(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, nil);
	MADDataReferenceAggregateDatasourceDouble *datasource = [[MADDataReferenceAggregateDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, datasource);

	MAD_PASS(reference.fieldKey == nil, "without an aggregate field there is no field key");
}

static void testFieldKeyIsNilWithoutADatasource(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Total", @"Invoice", context, document);
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, field);

	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, nil);

	MAD_PASS(reference.fieldKey == nil, "without a datasource there is no field key");
}

static void testFormattedStringUsesTheAggregateFieldType(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Total", @"Invoice", context, document);
	RptqDocumentElementAggregate *element = aggregateElementInContext(context, field);
	MADDocumentObjectDataReferenceAggregate *reference = referenceForElement(element, nil);

	NSString *formatted = [reference formattedStringForValue:@"abc"];
	MAD_PASS_EQUAL(formatted, @"abc", "the string formats through the aggregate field's schema type");
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceAggregateTests",
	MAD_TEST(testFactoryReturnsAggregateReference),
	MAD_TEST(testGroupAndFunctionSettingsAreSurfacedFromTheElement),
	MAD_TEST(testCalculateInMemoryIsTrueForFirstAndLastOnly),
	MAD_TEST(testFieldKeyQualifiesTheAggregateFieldWithTheTableAlias),
	MAD_TEST(testFieldKeyIsNilWithoutAnAggregateField),
	MAD_TEST(testFieldKeyIsNilWithoutADatasource),
	MAD_TEST(testFormattedStringUsesTheAggregateFieldType));
