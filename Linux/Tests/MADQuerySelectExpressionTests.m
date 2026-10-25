//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQuerySelectExpressionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQuerySelectExpressionTests.m: the SELECT-list
//  builders --
//
//    * MADQueryActiveQueryFields -- collects the RptqQueryField objects a report
//      actually references (data labels, aggregates, barcodes, links, groups).
//    * MADQuerySelectExpressionActiveFields -- renders those fields as the SELECT list.
//    * MADQuerySelectExpressionAllFields -- renders every field of every table the
//      query selects.
//    * MADQuerySelectExpression -- the dispatcher that picks between the two.
//
//  The store is a real SQLite file under a per-test temp directory, as in the
//  Xcode suite; the mock database is the portable half of MADMock
//  (Tests/Support/MADMock.h).
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADMock.h"
#import <MAD/MADQueryActiveQueryFields.h>
#import <MAD/MADQuerySelectExpression.h>
#import <MAD/MADQuerySelectExpressionActiveFields.h>
#import <MAD/MADQuerySelectExpressionAllFields.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

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

static RptqQueryField *queryFieldNamed(NSString *name, MADDataType type, NSString *tableName,
									   RptqStoreContext *context, RptqDocument *document) {
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

static void testActiveQueryFieldsEmptyContext(void) {
	RptqStoreContext *context = inMemoryContext();
	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	MAD_PASS(active.queryFields != nil, "the empty context still yields a set");
	MAD_PASS(active.queryFields.count == (NSUInteger)0, "the set is empty");
}

static void testActiveQueryFieldsCollectsReferencedFieldsOnce(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = queryFieldNamed(@"Id", MADDataTypeInteger, @"Invoice", context, document);
	RptqQueryField *right = queryFieldNamed(@"Id", MADDataTypeInteger, @"Customer", context, document);
	RptqQueryField *unreferenced = queryFieldNamed(@"Notes", MADDataTypeString, @"Invoice", context, document);

	RptqQueryLinks *link = (RptqQueryLinks *)[context insertObjectForEntity:@"RptqQueryLinks" identifier:0];
	link.hasLeftField = left;
	link.hasRightField = right;

	// The same field also groups: the result is a set, so it appears once.
	RptqQueryGroup *group = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = left;

	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	MAD_PASS(active.queryFields.count == (NSUInteger)2, "the two linked fields are collected");
	MAD_PASS([active.queryFields containsObject:left], "the left link field is collected");
	MAD_PASS([active.queryFields containsObject:right], "the right link field is collected");
	MAD_PASS(![active.queryFields containsObject:unreferenced], "the unreferenced field is not collected");
}

static void testActiveQueryFieldsCollectsElementReferences(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *labelField = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryField *aggregateField = queryFieldNamed(@"Amount", MADDataTypeDecimal, @"Invoice", context, document);
	RptqQueryField *barcodeField = queryFieldNamed(@"Code", MADDataTypeString, @"Invoice", context, document);

	RptqDocumentElementLabelDataField *label = (RptqDocumentElementLabelDataField *)[context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	label.referencesQueryField = labelField;

	RptqDocumentElementAggregate *aggregate = (RptqDocumentElementAggregate *)[context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	aggregate.aggregateField = aggregateField;

	RptqDocumentElementBarcode *barcode = (RptqDocumentElementBarcode *)[context insertObjectForEntity:@"RptqDocumentElementBarcode" identifier:0];
	barcode.referencesField1 = barcodeField;

	MADQueryActiveQueryFields *active = [[MADQueryActiveQueryFields alloc] initWithContext:context];

	MAD_PASS(active.queryFields.count == (NSUInteger)3, "the three element-referenced fields are collected");
	MAD_PASS([active.queryFields containsObject:labelField], "the data label's field is collected");
	MAD_PASS([active.queryFields containsObject:aggregateField], "the aggregate's field is collected");
	MAD_PASS([active.queryFields containsObject:barcodeField], "the barcode's field is collected");
}

#pragma mark - MADQuerySelectExpressionActiveFields

static void testActiveFieldsSelectList(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);

	RptqQueryGroup *group = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = field;

	MADQuerySelectExpressionActiveFields *select;
	select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:[MADMock mockDatabase]
												   forManagedObjectContext:context];

	MAD_PASS_EQUAL(select.sql, @"\tInvoice0.Name", "the select list carries the qualified field");
	MAD_PASS(select.fieldKeys.count == (NSUInteger)1, "one field key is reported");
	MAD_PASS_EQUAL(select.fieldKeys.firstObject, @"Invoice0.Name", "the field key is the qualified name");
	MAD_PASS_EQUAL(select.fields[@"Invoice0.Name"], field.databaseSchemaField, "the field maps back to its schema field");
}

// The SELECT list's order used to be NSSet enumeration order, and that order is not
// stable: not insertion order, not platform order, and -- measured here -- not even
// the same between two documents built by the same fixture in one process.  docs/project/BUGS.md
// recorded it; the order is now defined as the column alias, so the generated SQL,
// the row cache and every export agree (the order tests below).  What is pinned here
// is the part that must not vary: the *content* of the list, whichever order the
// fields were created in and whichever order the set happens to enumerate.
static void testActiveFieldsSelectListContentComesFromTheSet(void) {
	NSSet *firstFields = nil;
	NSSet *secondFields = nil;
	NSSet *firstLines = nil;
	NSSet *secondLines = nil;

	for (NSNumber *reversed in @[ @NO, @YES ]) {
		RptqStoreContext *context = inMemoryContext();
		RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
		NSArray <NSString *> *names = reversed.boolValue ? @[ @"Zulu", @"Alpha" ] : @[ @"Alpha", @"Zulu" ];

		NSMutableArray <RptqQueryField *> *fields = [NSMutableArray array];
		for (NSString *name in names) {
			[fields addObject: queryFieldNamed(name, MADDataTypeString, @"Invoice", context, document)];
		}
		for (RptqQueryField *field in fields) {
			// The element is what makes a field active.
			RptqDocumentElementLabelDataField *label =
				(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:
													  NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
			label.referencesQueryField = field;
		}

		MADQuerySelectExpressionActiveFields *select;
		select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase: [MADMock mockDatabase]
													   forManagedObjectContext: context];

		MAD_PASS(select.fieldKeys.count == 2, "both active fields are in the list");
		// Hoisted: a comma inside @[...] splits a macro's arguments (Linux/AGENTS.md).
		NSSet *expectedFields = [NSSet setWithArray: @[ @"Invoice0.Alpha", @"Invoice0.Zulu" ]];
		NSSet *listedFields = [NSSet setWithArray: select.fieldKeys];
		MAD_PASS([listedFields isEqualToSet: expectedFields], "the list holds both fields and only them");

		NSSet *lines = [NSSet setWithArray: [select.sql componentsSeparatedByString: @",\n"]];
		if (reversed.boolValue) {
			secondFields = listedFields;
			secondLines = lines;
		} else {
			firstFields = listedFields;
			firstLines = lines;
		}
	}

	MAD_PASS_EQUAL(firstFields, secondFields, "the same fields, whichever order they were created in");
	MAD_PASS_EQUAL(firstLines, secondLines, "the same SELECT list, whichever order they were created in");
}

// The order itself: the column alias decides, so the list reads the same whichever
// order the fields were created in -- and the same here as on Apple.
static void testActiveFieldsSelectListIsOrderedByColumnAlias(void) {
	NSArray <NSString *> *expectedFieldKeys = @[ @"Invoice0.Alpha", @"Invoice0.Zulu" ];
	NSString *expectedSQL = @"\tInvoice0.Alpha,\n\tInvoice0.Zulu";

	for (NSNumber *reversed in @[ @NO, @YES ]) {
		RptqStoreContext *context = inMemoryContext();
		RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
		NSArray <NSString *> *names = reversed.boolValue ? @[ @"Zulu", @"Alpha" ] : @[ @"Alpha", @"Zulu" ];

		for (NSString *name in names) {
			RptqQueryField *field = queryFieldNamed(name, MADDataTypeString, @"Invoice", context, document);
			// The element is what makes a field active.
			RptqDocumentElementLabelDataField *label =
				(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:
													  NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
			label.referencesQueryField = field;
		}

		MADQuerySelectExpressionActiveFields *select;
		select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase: [MADMock mockDatabase]
													   forManagedObjectContext: context];

		MAD_PASS_EQUAL(select.fieldKeys, expectedFieldKeys, "the field keys are ordered by column alias");
		MAD_PASS_EQUAL(select.sql, expectedSQL, "the SELECT list is ordered by column alias");
	}
}

static void testActiveFieldsSelectListIsEmptyWithoutActiveFields(void) {
	RptqStoreContext *context = inMemoryContext();

	MADQuerySelectExpressionActiveFields *select;
	select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:[MADMock mockDatabase]
												   forManagedObjectContext:context];

	MAD_PASS(select.sql == nil, "no active fields means no select list");
	MAD_PASS(select.fieldKeys.count == (NSUInteger)0, "no field keys are reported");
}

#pragma mark - MADQuerySelectExpressionAllFields

static void testAllFieldsSelectList(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *name = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryTable *table = name.inQueryTable;
	RptqQueryField *amount = queryFieldNamed(@"Amount", MADDataTypeDecimal, @"Invoice", context, document);
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
	MAD_PASS([table.hasQueryFields containsObject:name], "the first field is on the table");
	MAD_PASS([table.hasQueryFields containsObject:amount], "the second field is on the table");

	// The table's fields are a set, so both are asserted present rather than ordered.
	NSString *sql = select.sql;
	MAD_PASS([sql containsString:@"\tInvoice0.Name"], "the select list carries the first field");
	MAD_PASS([sql containsString:@"\tInvoice0.Amount"], "the select list carries the second field");
	MAD_PASS([sql containsString:@",\n"], "the fields are comma-separated");
}

// The table's fields are a set, so the order used to be hash order; the field name
// decides now.
static void testAllFieldsSelectListIsOrderedByFieldName(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *name = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryTable *table = name.inQueryTable;
	RptqQueryField *amount = queryFieldNamed(@"Amount", MADDataTypeDecimal, @"Invoice", context, document);
	amount.inQueryTable = table;

	MTVertex *vertex = [[MTVertex alloc] initWithID:table.identifier andObject:@(table.identifier)];
	MTPair *pair = [[MTPair alloc] initWithFormer:vertex andLatter:nil];

	MADQuerySelectExpressionAllFields *select;
	select = [[MADQuerySelectExpressionAllFields alloc] initWithDatabase: [MADMock mockDatabase]
																 tables: @[ pair ]
											   forManagedObjectContext: context];

	MAD_PASS_EQUAL(select.sql, @"\tInvoice0.Amount,\n\tInvoice0.Name", "the fields are ordered by name");
}

#pragma mark - MADQuerySelectExpression dispatcher

static void testDispatcherChoosesImplementation(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDatabase *database = [MADMock mockDatabase];

	MADQuerySelectExpression *active = [[MADQuerySelectExpression alloc] initWithDatabase:database
																				   tables:@[]
																	usingOnlyActiveFields:YES
																  forManagedObjectContext:context];
	MAD_PASS_EQUAL(NSStringFromClass([active class]), @"MADQuerySelectExpressionActiveFields",
				   "the dispatcher picks the active-fields builder");

	MADQuerySelectExpression *all = [[MADQuerySelectExpression alloc] initWithDatabase:database
																				tables:@[]
																 usingOnlyActiveFields:NO
															   forManagedObjectContext:context];
	MAD_PASS_EQUAL(NSStringFromClass([all class]), @"MADQuerySelectExpressionAllFields",
				   "the dispatcher picks the all-fields builder");
}

MAD_TEST_MAIN("MADQuerySelectExpressionTests",
	MAD_TEST(testActiveQueryFieldsEmptyContext),
	MAD_TEST(testActiveQueryFieldsCollectsReferencedFieldsOnce),
	MAD_TEST(testActiveQueryFieldsCollectsElementReferences),
	MAD_TEST(testActiveFieldsSelectList),
	MAD_TEST(testActiveFieldsSelectListContentComesFromTheSet),
	MAD_TEST(testActiveFieldsSelectListIsOrderedByColumnAlias),
	MAD_TEST(testActiveFieldsSelectListIsEmptyWithoutActiveFields),
	MAD_TEST(testAllFieldsSelectList),
	MAD_TEST(testAllFieldsSelectListIsOrderedByFieldName),
	MAD_TEST(testDispatcherChoosesImplementation));
