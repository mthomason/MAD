//
//  MADQuerySelectExpressionTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for the SELECT-list builders:
//
//    * MADQueryActiveQueryFields -- collects the RptqQueryField objects a report
//      actually references (data labels, aggregates, barcodes, links, groups).
//    * MADQuerySelectExpressionActiveFields -- renders those fields as the SELECT list.
//    * MADQuerySelectExpressionAllFields -- renders every field of every table the
//      query selects.
//    * MADQuerySelectExpression -- the dispatcher that picks between the two.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADMock.h"
#import "MADQueryActiveQueryFields.h"
#import "MADQuerySelectExpression.h"
#import "MADQuerySelectExpressionActiveFields.h"
#import "MADQuerySelectExpressionAllFields.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

@interface MADQuerySelectExpressionTests : XCTestCase
@end

@implementation MADQuerySelectExpressionTests

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
							   type:(MADDataType)type
						  tableName:(NSString *)tableName
							context:(RptqStoreContext *)context
						   document:(RptqDocument *)document {

	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

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

#pragma mark - MADQueryActiveQueryFields

- (void)testActiveQueryFieldsEmptyContext {
	RptqStoreContext *context = [self inMemoryContext];
	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	XCTAssertNotNil(active.queryFields);
	XCTAssertEqual(active.queryFields.count, (NSUInteger)0);
}

- (void)testActiveQueryFieldsCollectsReferencedFieldsOnce {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = [self queryFieldNamed:@"Id" type:MADDataTypeInteger tableName:@"Invoice" context:context document:document];
	RptqQueryField *right = [self queryFieldNamed:@"Id" type:MADDataTypeInteger tableName:@"Customer" context:context document:document];
	RptqQueryField *unreferenced = [self queryFieldNamed:@"Notes" type:MADDataTypeString tableName:@"Invoice" context:context document:document];

	RptqQueryLinks *link = [context insertObjectForEntity:@"RptqQueryLinks" identifier:0];
	link.hasLeftField = left;
	link.hasRightField = right;

	// The same field also groups: the result is a set, so it appears once.
	RptqQueryGroup *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = left;

	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	XCTAssertEqual(active.queryFields.count, (NSUInteger)2);
	XCTAssertTrue([active.queryFields containsObject:left]);
	XCTAssertTrue([active.queryFields containsObject:right]);
	XCTAssertFalse([active.queryFields containsObject:unreferenced]);
}

- (void)testActiveQueryFieldsCollectsElementReferences {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *labelField = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];
	RptqQueryField *aggregateField = [self queryFieldNamed:@"Amount" type:MADDataTypeDecimal tableName:@"Invoice" context:context document:document];
	RptqQueryField *barcodeField = [self queryFieldNamed:@"Code" type:MADDataTypeString tableName:@"Invoice" context:context document:document];

	RptqDocumentElementLabelDataField *label = [context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	label.referencesQueryField = labelField;

	RptqDocumentElementAggregate *aggregate = [context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	aggregate.aggregateField = aggregateField;

	RptqDocumentElementBarcode *barcode = [context insertObjectForEntity:@"RptqDocumentElementBarcode" identifier:0];
	barcode.referencesField1 = barcodeField;

	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	XCTAssertEqual(active.queryFields.count, (NSUInteger)3);
	XCTAssertTrue([active.queryFields containsObject:labelField]);
	XCTAssertTrue([active.queryFields containsObject:aggregateField]);
	XCTAssertTrue([active.queryFields containsObject:barcodeField]);
}

#pragma mark - MADQuerySelectExpressionActiveFields

- (void)testActiveFieldsSelectList {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];

	RptqQueryGroup *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = field;

	MADQuerySelectExpressionActiveFields *select;
	select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:[MADMock mockDatabase]
												   forManagedObjectContext:context];

	XCTAssertEqualObjects(select.sql, @"\tInvoice0.Name");
	XCTAssertEqual(select.fieldKeys.count, (NSUInteger)1);
	XCTAssertEqualObjects(select.fieldKeys.firstObject, @"Invoice0.Name");
	XCTAssertEqualObjects(select.fields[@"Invoice0.Name"], field.databaseSchemaField);
}

- (void)testActiveFieldsSelectListIsEmptyWithoutActiveFields {
	RptqStoreContext *context = [self inMemoryContext];

	MADQuerySelectExpressionActiveFields *select;
	select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:[MADMock mockDatabase]
												   forManagedObjectContext:context];

	XCTAssertNil(select.sql);
	XCTAssertEqual(select.fieldKeys.count, (NSUInteger)0);
}

#pragma mark - MADQuerySelectExpressionAllFields

- (void)testAllFieldsSelectList {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *name = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];
	RptqQueryTable *table = name.inQueryTable;
	RptqQueryField *amount = [self queryFieldNamed:@"Amount" type:MADDataTypeDecimal tableName:@"Invoice" context:context document:document];
	// The fixture mints a fresh query table per field; put both fields on the one table
	// the SELECT list is asked about.
	amount.inQueryTable = table;

	MTVertex *vertex = [[MTVertex alloc] initWithID:table.identifier andObject:@(table.identifier)];
	MTPair *pair = [[MTPair alloc] initWithFormer:vertex andLatter:nil];

	MADQuerySelectExpressionAllFields *select;
	select = [[MADQuerySelectExpressionAllFields alloc] initWithDatabase:[MADMock mockDatabase]
																 tables:@[ pair ]
											   forManagedObjectContext:context];

	// The to-one write on each field populates the table's to-many inverse.
	XCTAssertTrue([table.hasQueryFields containsObject:name]);
	XCTAssertTrue([table.hasQueryFields containsObject:amount]);

	// The table's fields are a set, so both are asserted present rather than ordered.
	NSString *sql = select.sql;
	XCTAssertTrue([sql containsString:@"\tInvoice0.Name"]);
	XCTAssertTrue([sql containsString:@"\tInvoice0.Amount"]);
	XCTAssertTrue([sql containsString:@",\n"]);
}

#pragma mark - MADQuerySelectExpression dispatcher

- (void)testDispatcherChoosesImplementation {
	RptqStoreContext *context = [self inMemoryContext];
	MADDatabase *database = [MADMock mockDatabase];

	MADQuerySelectExpression *active = [[MADQuerySelectExpression alloc] initWithDatabase:database
																				   tables:@[]
																	usingOnlyActiveFields:YES
																  forManagedObjectContext:context];
	XCTAssertEqualObjects(NSStringFromClass([active class]), @"MADQuerySelectExpressionActiveFields");

	MADQuerySelectExpression *all = [[MADQuerySelectExpression alloc] initWithDatabase:database
																				tables:@[]
																 usingOnlyActiveFields:NO
															   forManagedObjectContext:context];
	XCTAssertEqualObjects(NSStringFromClass([all class]), @"MADQuerySelectExpressionAllFields");
}

@end
