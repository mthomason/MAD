//
//  MADSQLQueryCompilerTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the pasted-SQL importer's write half (MAD_SQL_ENTRY.md §6.3,
//  §6.4, §10.4): the happy-path apply produces exactly the Rptq rows the visual
//  designer would create and stores the entered text verbatim; the replace path
//  leaves no orphan; the conflict path aborts with the store untouched; and the
//  fixpoint round trip -- model to SQL, parse, compile, SQL again -- is the
//  statement that defines the feature.
//
//  The document under test is MADHeadlessDocument, the Linux-side member of the
//  MADSQLQueryDocument pair: its helpers write the same definition rows
//  MADocument's write, so what is asserted here holds for the app's document
//  too.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import <MAD/MADSQLCompileError.h>
#import <MAD/MADSQLParser.h>
#import <MAD/MADSQLStatement.h>
#import <MAD/MADSQLStatementResolver.h>
#import <MAD/MADSQLQueryCompiler.h>
#import "MADQueryFull.h"
#import "MADQueryPredicate.h"
#import "MADPredicateOperator.h"
#import "MADQueryLinkType.h"
#import "MADSortOrder.h"
#import "MADocumentSectionType.h"
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADStore.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStoreObject.h>
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementBarcode.h"

#import "MADMock.h"

#pragma mark - Test double

// The generator asks its data delegate for the database whose dialect to emit;
// the fixpoint uses the same mock the golden tests do.
@interface MADSQLTestDataDelegate : NSObject <MADDataProtocol>
@property (nonatomic, strong) MADDatabase *database;
@end

@implementation MADSQLTestDataDelegate
- (NSArray *)sortDescriptors { return @[]; }
@end

@interface MADSQLQueryCompilerTests : XCTestCase
@property (nonatomic, strong) NSURL *directory;
@property (nonatomic, strong) MADSQLTestDataDelegate *dataDelegate;
@end

@implementation MADSQLQueryCompilerTests

#pragma mark - Lifecycle

- (void)setUp {
	[super setUp];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
	self.directory = [NSURL fileURLWithPath:path isDirectory:YES];
	self.dataDelegate = [[MADSQLTestDataDelegate alloc] init];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	self.directory = nil;
	[super tearDown];
}

#pragma mark - The fixture

// A headless document over a fresh portable store, with the three schema tables
// the statements name: customers(id, name), invoices(id, customer_id, amount),
// lines(id, invoice_id, sku).
- (MADHeadlessDocument *)makeDocumentNamed:(NSString *)name {
	// The document's guts directory is keyed by the file name in the app's
	// shared ~/tmp (MADURLFactory newURLDocumentArchiveForFileURL:), so a test
	// fixture must carry a name no earlier run used or it reopens their store.
	NSString *unique = [[NSString alloc] initWithFormat:@"%@-%@.mad", name, NSUUID.UUID.UUIDString];
	NSURL *url = [self.directory URLByAppendingPathComponent:unique];
	MADHeadlessDocument *document = [[MADHeadlessDocument alloc] initWithFileURL:url];
	NSError *error = nil;
	XCTAssertTrue([document.documentStore openWithError:&error], @"open failed: %@", error);

	RptqStoreContext *context = document.storeContext;
	RptqDocument *rptqDocument = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDatabase *database = (RptqDatabase *)[context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:20];
	[rptqDocument addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];

	[self addSchemaTableNamed:@"customers" fields:@[ @[ @"id", @(MADDataTypeInteger) ], @[ @"name", @(MADDataTypeString) ] ] database:database context:context];
	[self addSchemaTableNamed:@"invoices" fields:@[ @[ @"id", @(MADDataTypeInteger) ], @[ @"customer_id", @(MADDataTypeInteger) ], @[ @"amount", @(MADDataTypeDecimal) ] ] database:database context:context];
	[self addSchemaTableNamed:@"lines" fields:@[ @[ @"id", @(MADDataTypeInteger) ], @[ @"invoice_id", @(MADDataTypeInteger) ], @[ @"sku", @(MADDataTypeString) ] ] database:database context:context];

	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);
	return document;
}

- (void)addSchemaTableNamed:(NSString *)name
					 fields:(NSArray<NSArray *> *)fields
				   database:(RptqDatabase *)database
					context:(RptqStoreContext *)context {
	RptqDatabaseSchemaTable *schemaTable =
		[RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context name:name andQueryable:YES];
	[database addHasTablesObject:schemaTable];
	for (NSArray *fieldInfo in fields) {
		MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:fieldInfo[0]];
		databaseField.fieldType = (MADDataType)[fieldInfo[1] integerValue];
		RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context andField:databaseField];
		schemaField.inTable = schemaTable;
	}
}

- (RptqQuery *)queryOfDocument:(MADHeadlessDocument *)document {
	return document.activeDocumentModel.mainQuery;
}

// The parser's schema: table name -> field names, read off the document's own
// schema rows.
- (NSDictionary *)schemaDictionaryForDocument:(MADHeadlessDocument *)document {
	NSMutableDictionary *schema = [NSMutableDictionary dictionary];
	for (RptqDatabaseSchemaTable *table in document.activeDocumentModel.defaultDatabase.hasTables) {
		NSMutableArray *names = [NSMutableArray array];
		for (RptqDatabaseSchemaField *field in table.hasFields) {
			[names addObject:field.name];
		}
		schema[table.name] = names;
	}
	return schema;
}

// The whole front half: parse, resolve, compile, apply -- one call per test.
- (BOOL)applyStatement:(NSString *)sql
		   toDocument:(MADHeadlessDocument *)document
				error:(NSError * __autoreleasing *)error {
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
									 identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													   schema:[self schemaDictionaryForDocument:document]];
	MADSQLStatement *statement = [parser parseStatement:error];
	if (statement == nil) return NO;

	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement
																				  database:document.activeDocumentModel.defaultDatabase];
	MADSQLQueryPlan *plan = [resolver resolveWithError:error];
	if (plan == nil) return NO;

	MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																	 document:document
																		query:[self queryOfDocument:document]
																	  context:document.storeContext];
	return [compiler applyWithError:error];
}

// The designer's add-table flow, for the fixtures the apply runs over: one
// query table (with a field per schema field) for the named schema table.
- (RptqQueryTable *)addQueryTableNamed:(NSString *)name
							  toQuery:(RptqQuery *)query
							  database:(RptqDatabase *)database
							   context:(RptqStoreContext *)context {
	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in database.hasTables) {
		if ([candidate.name isEqualToString:name]) { schemaTable = candidate; break; }
	}
	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																   database:database
													 forManagedObjectContext:context];
	NSMutableSet *fields = [NSMutableSet setWithCapacity:schemaTable.hasFields.count];
	for (RptqDatabaseSchemaField *schemaField in schemaTable.hasFields) {
		RptqQueryField *queryField = [RptqQueryField newQueryField:context];
		queryField.inQueryTable = queryTable;
		queryField.databaseSchemaField = schemaField;
		[fields addObject:queryField];
	}
	queryTable.hasQueryFields = fields;
	[query addHasQueryTablesObject:queryTable];
	return queryTable;
}

- (RptqQueryField *)queryFieldNamed:(NSString *)name onQueryTable:(RptqQueryTable *)queryTable {
	for (RptqQueryField *field in queryTable.hasQueryFields) {
		if ([field.databaseSchemaField.name isEqualToString:name]) return field;
	}
	return nil;
}

#pragma mark - Happy path

- (void)testHappyPathApplyBuildsTheDesignersRows {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"happy.mad"];
	RptqQuery *query = [self queryOfDocument:document];
	RptqStoreContext *context = document.storeContext;

	NSString *sql =
		@"SELECT customers.name, invoices.amount FROM customers INNER JOIN invoices "
		@"ON customers.id = invoices.customer_id WHERE invoices.amount > 100 "
		@"AND customers.name = 'A' GROUP BY customers.name ORDER BY customers.name DESC";
	NSError *error = nil;
	XCTAssertTrue([self applyStatement:sql toDocument:document error:&error], @"%@", error);

	// Tables: one per plan table, with the right schema refs and copy index.
	XCTAssertEqual(query.hasQueryTables.count, (NSUInteger)2);
	RptqQueryTable *customersTable = nil;
	RptqQueryTable *invoicesTable = nil;
	for (RptqQueryTable *table in query.hasQueryTables) {
		if ([table.databaseSchemaTable.name isEqualToString:@"customers"]) customersTable = table;
		if ([table.databaseSchemaTable.name isEqualToString:@"invoices"]) invoicesTable = table;
	}
	XCTAssertNotNil(customersTable);
	XCTAssertNotNil(invoicesTable);
	XCTAssertEqual(customersTable.dropIndex, (int64_t)0);
	XCTAssertEqual(invoicesTable.dropIndex, (int64_t)0);

	// Fields: the add-table flow's one query field per schema field, wired up.
	XCTAssertEqual(customersTable.hasQueryFields.count, (NSUInteger)2);
	XCTAssertEqual(invoicesTable.hasQueryFields.count, (NSUInteger)3);
	XCTAssertEqual([context objectsForEntity:@"RptqQueryField"].count, (NSUInteger)5);
	for (RptqQueryField *field in customersTable.hasQueryFields) {
		XCTAssertEqual(field.inQueryTable, customersTable);
		XCTAssertEqualObjects(field.databaseSchemaField.inTable.name, @"customers");
	}

	// Links: the join type, the fields and the string IDs the factory writes.
	XCTAssertEqual(query.hasQueryLinks.count, (NSUInteger)1);
	RptqQueryLinks *link = query.hasQueryLinks.anyObject;
	XCTAssertEqual(link.type, (int16_t)MADLinkTypeInnerJoin);
	XCTAssertEqualObjects(link.hasLeftField.databaseSchemaField.name, @"id");
	XCTAssertEqualObjects(link.hasLeftField.inQueryTable.databaseSchemaTable.name, @"customers");
	XCTAssertEqualObjects(link.hasRightField.databaseSchemaField.name, @"customer_id");
	XCTAssertEqualObjects(link.hasRightField.inQueryTable.databaseSchemaTable.name, @"invoices");
	XCTAssertEqualObjects(link.fieldLeftID, @"id");
	XCTAssertEqualObjects(link.tableLeftID, @"customers");
	XCTAssertEqualObjects(link.fieldRightID, @"customer_id");
	XCTAssertEqualObjects(link.tableRightID, @"invoices");

	// Predicates: the operator, the field, and the value string -- the two the
	// statement names.
	XCTAssertEqual(query.hasQueryPredicate.count, (NSUInteger)2);
	RptqQueryPredicate *amountPredicate = nil;
	RptqQueryPredicate *namePredicate = nil;
	for (RptqQueryPredicate *predicate in query.hasQueryPredicate) {
		if (predicate.comparson == (int16_t)MADPredicateOperatorGreaterThan) amountPredicate = predicate;
		if (predicate.comparson == (int16_t)MADPredicateOperatorEqual) namePredicate = predicate;
	}
	XCTAssertNotNil(amountPredicate);
	XCTAssertEqualObjects(amountPredicate.hasLeftField.databaseSchemaField.name, @"amount");
	XCTAssertEqualObjects(amountPredicate.rigthFieldID, @"100");
	XCTAssertNotNil(namePredicate);
	XCTAssertEqualObjects(namePredicate.hasLeftField.databaseSchemaField.name, @"name");
	XCTAssertEqualObjects(namePredicate.rigthFieldID, @"A");

	// Groups: the row, its sort and weight, and the report's header and footer
	// sections with their rows.
	XCTAssertEqual(query.hasQueryGroups.count, (NSUInteger)1);
	RptqQueryGroup *group = query.hasQueryGroups.anyObject;
	XCTAssertEqualObjects(group.hasField.databaseSchemaField.name, @"name");
	XCTAssertEqual(group.sort, (int16_t)MADSortOrderDecending);
	// The group factory weights the first group 1 (lastWeight + 1, the same
	// arithmetic the designer's own path uses).
	XCTAssertEqual(group.weight, (int16_t)1);
	XCTAssertEqual(group.hasSection.count, (NSUInteger)2);
	RptqDocumentSection *header = nil;
	RptqDocumentSection *footer = nil;
	for (RptqDocumentSection *section in group.hasSection) {
		if (section.type == (int16_t)MADDocumentSectionTypeGroupHeader) header = section;
		if (section.type == (int16_t)MADDocumentSectionTypeGroupFooter) footer = section;
	}
	XCTAssertNotNil(header);
	XCTAssertNotNil(footer);
	XCTAssertEqualObjects(header.inGroup, group);
	XCTAssertEqualObjects(footer.inGroup, group);
	XCTAssertEqual(header.hasRows.count, (NSUInteger)1);
	XCTAssertEqual(footer.hasRows.count, (NSUInteger)1);

	// The entered text is part of the document, verbatim.
	XCTAssertEqualObjects(query.sqlSourceText, sql);

	// One save: everything above survives a close and reopen.
	[document.documentStore close];
	error = nil;
	XCTAssertTrue([document.documentStore openWithError:&error], @"reopen failed: %@", error);
	XCTAssertEqualObjects([self queryOfDocument:document].sqlSourceText, sql);
	XCTAssertEqual([self queryOfDocument:document].hasQueryTables.count, (NSUInteger)2);
	XCTAssertEqual([self queryOfDocument:document].hasQueryPredicate.count, (NSUInteger)2);
	XCTAssertEqual([self queryOfDocument:document].hasQueryGroups.count, (NSUInteger)1);
}

#pragma mark - Replace path

- (void)testApplyOverAPopulatedQueryReplacesItWithoutOrphans {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"replace.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	// The existing query: customers and lines, a link, a predicate, a group.
	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *customersID = [self queryFieldNamed:@"id" onQueryTable:customersTable];
	RptqQueryField *linesInvoiceID = [self queryFieldNamed:@"invoice_id" onQueryTable:linesTable];
	RptqQueryLinks *oldLink = [RptqQueryLinks newQueryLinksWithLeftField:customersID rightField:linesInvoiceID joinType:MADLinkTypeInnerJoin managedObjectContext:context];
	[query addHasQueryLinksObject:oldLink];

	RptqQueryField *customersName = [self queryFieldNamed:@"name" onQueryTable:customersTable];
	RptqQueryPredicate *oldPredicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	oldPredicate.comparson = (int16_t)MADPredicateOperatorEqual;
	oldPredicate.hasLeftField = customersName;
	oldPredicate.rigthFieldID = @"Old";
	[query addHasQueryPredicateObject:oldPredicate];

	[document addQueryGroupWithQueryField:customersName.identifier andSortOrder:MADSortOrderAccending];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	// The apply: customers joins invoices; lines is dropped, everything else
	// replaced.
	NSString *sql = @"SELECT customers.name, invoices.amount FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id WHERE invoices.amount >= 5";
	NSError *error = nil;
	XCTAssertTrue([self applyStatement:sql toDocument:document error:&error], @"%@", error);

	XCTAssertEqual([context objectsForEntity:@"RptqQueryTable"].count, (NSUInteger)2);
	XCTAssertEqual([context objectsForEntity:@"RptqQueryField"].count, (NSUInteger)5);
	XCTAssertEqual([context objectsForEntity:@"RptqQueryLinks"].count, (NSUInteger)1);
	XCTAssertEqual([context objectsForEntity:@"RptqQueryPredicate"].count, (NSUInteger)1);
	XCTAssertEqual([context objectsForEntity:@"RptqQueryGroup"].count, (NSUInteger)0);

	RptqQueryLinks *link = query.hasQueryLinks.anyObject;
	XCTAssertEqualObjects(link.hasLeftField.inQueryTable.databaseSchemaTable.name, @"customers");
	XCTAssertEqualObjects(link.hasRightField.inQueryTable.databaseSchemaTable.name, @"invoices");

	RptqQueryPredicate *predicate = query.hasQueryPredicate.anyObject;
	XCTAssertEqual(predicate.comparson, (int16_t)MADPredicateOperatorGreaterThanOrEqualTo);
	XCTAssertEqualObjects(predicate.rigthFieldID, @"5");

	// The dropped table's rows are gone, fields included; no line rows remain.
	for (RptqQueryTable *table in query.hasQueryTables) {
		XCTAssertNotEqualObjects(table.databaseSchemaTable.name, @"lines");
	}

	XCTAssertEqualObjects(query.sqlSourceText, sql);
}

#pragma mark - Conflict path

- (void)buildConflictingElement:(Class)elementClass
						field:(RptqQueryField *)field
					  document:(MADHeadlessDocument *)document {
	RptqStoreContext *context = document.storeContext;
	RptqDocumentElement *element = [context insertObjectForEntity:NSStringFromClass(elementClass) identifier:0];
	element.inSectionRow = document.activeDocumentModel.hasDetailSection.hasRows.firstObject;
	if ([element isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
		((RptqDocumentElementLabelDataField *)element).referencesQueryField = field;
	} else if ([element isKindOfClass:[RptqDocumentElementAggregate class]]) {
		((RptqDocumentElementAggregate *)element).aggregateField = field;
	} else {
		((RptqDocumentElementBarcode *)element).referencesField1 = field;
	}
}

- (void)assertApplyFailsWithDesignerConflict:(MADHeadlessDocument *)document sql:(NSString *)sql {
	// The before snapshot: everything the store holds, including the previous
	// entered text.
	RptqQuery *query = [self queryOfDocument:document];
	query.sqlSourceText = @"PREVIOUS TEXT";
	NSError *saveError = nil;
	XCTAssertTrue([document.storeContext save:&saveError], @"save failed: %@", saveError);

	MADStoreGraph *before = [document.storeContext.store allObjectsWithError:&saveError];
	XCTAssertNotNil(before, @"%@", saveError);

	NSError *error = nil;
	XCTAssertFalse([self applyStatement:sql toDocument:document error:&error]);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, (NSInteger)MADSQLCompileErrorDesignerConflict);
	XCTAssertEqualObjects(error.domain, MADSQLCompileErrorDomain);
	XCTAssertNotNil(error.userInfo[NSLocalizedDescriptionKey]);

	// Nothing changed: not the rows, not the entered text.
	XCTAssertEqualObjects([self queryOfDocument:document].sqlSourceText, @"PREVIOUS TEXT");
	MADStoreGraph *after = [document.storeContext.store allObjectsWithError:&saveError];
	XCTAssertNotNil(after, @"%@", saveError);
	XCTAssertTrue([after isEqualToGraph:before], @"the failed apply changed the store");
}

- (void)testALabelDataElementOnADroppedTableBlocksTheApply {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"conflict-label.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *linesSKU = [self queryFieldNamed:@"sku" onQueryTable:linesTable];
	[self buildConflictingElement:[RptqDocumentElementLabelDataField class] field:linesSKU document:document];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	// customers alone would drop lines, whose sku the designer shows.
	[self assertApplyFailsWithDesignerConflict:document sql:@"SELECT customers.name FROM customers"];
}

- (void)testAnAggregateElementOnADroppedTableBlocksTheApply {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"conflict-aggregate.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *linesID = [self queryFieldNamed:@"id" onQueryTable:linesTable];
	[self buildConflictingElement:[RptqDocumentElementAggregate class] field:linesID document:document];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	[self assertApplyFailsWithDesignerConflict:document sql:@"SELECT customers.name FROM customers"];
}

- (void)testABarcodeElementOnADroppedTableBlocksTheApply {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"conflict-barcode.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *linesSKU = [self queryFieldNamed:@"sku" onQueryTable:linesTable];
	[self buildConflictingElement:[RptqDocumentElementBarcode class] field:linesSKU document:document];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	[self assertApplyFailsWithDesignerConflict:document sql:@"SELECT customers.name FROM customers"];
}

- (void)testAGroupOnADroppedTableBlocksTheApply {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"conflict-group.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *linesSKU = [self queryFieldNamed:@"sku" onQueryTable:linesTable];
	[document addQueryGroupWithQueryField:linesSKU.identifier andSortOrder:MADSortOrderAccending];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	[self assertApplyFailsWithDesignerConflict:document sql:@"SELECT customers.name FROM customers"];
}

- (void)testAnElementOnAKeptTableDoesNotBlockTheApply {
	MADHeadlessDocument *document = [self makeDocumentNamed:@"conflict-kept.mad"];
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = [self queryOfDocument:document];
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:query database:database context:context];
	RptqQueryTable *linesTable = [self addQueryTableNamed:@"lines" toQuery:query database:database context:context];
	RptqQueryField *customersName = [self queryFieldNamed:@"name" onQueryTable:customersTable];
	[self buildConflictingElement:[RptqDocumentElementLabelDataField class] field:customersName document:document];
	NSError *saveError = nil;
	XCTAssertTrue([context save:&saveError], @"save failed: %@", saveError);

	// customers is kept, so the designer's element survives the apply.
	NSError *error = nil;
	XCTAssertTrue([self applyStatement:@"SELECT customers.name FROM customers" toDocument:document error:&error], @"%@", error);
	XCTAssertEqual([context objectsForEntity:@"RptqDocumentElementLabelDataField"].count, (NSUInteger)1);
}

#pragma mark - The fixpoint

- (void)testFixpointRoundTrip {
	// The model, built through the designer's own factories.
	MADHeadlessDocument *first = [self makeDocumentNamed:@"fixpoint-first.mad"];
	RptqStoreContext *firstContext = first.storeContext;
	RptqQuery *firstQuery = [self queryOfDocument:first];
	RptqDatabase *firstDatabase = first.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = [self addQueryTableNamed:@"customers" toQuery:firstQuery database:firstDatabase context:firstContext];
	RptqQueryTable *invoicesTable = [self addQueryTableNamed:@"invoices" toQuery:firstQuery database:firstDatabase context:firstContext];

	RptqQueryField *customersID = [self queryFieldNamed:@"id" onQueryTable:customersTable];
	RptqQueryField *invoicesCustomerID = [self queryFieldNamed:@"customer_id" onQueryTable:invoicesTable];
	RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField:customersID rightField:invoicesCustomerID joinType:MADLinkTypeInnerJoin managedObjectContext:firstContext];
	[firstQuery addHasQueryLinksObject:link];

	RptqQueryField *customersName = [self queryFieldNamed:@"name" onQueryTable:customersTable];
	RptqQueryPredicate *namePredicate = (RptqQueryPredicate *)[firstContext insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	namePredicate.comparson = (int16_t)MADPredicateOperatorEqual;
	namePredicate.hasLeftField = customersName;
	namePredicate.rigthFieldID = @"O'Brien";
	[firstQuery addHasQueryPredicateObject:namePredicate];

	RptqQueryField *invoicesAmount = [self queryFieldNamed:@"amount" onQueryTable:invoicesTable];
	RptqQueryPredicate *amountPredicate = (RptqQueryPredicate *)[firstContext insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	amountPredicate.comparson = (int16_t)MADPredicateOperatorGreaterThan;
	amountPredicate.hasLeftField = invoicesAmount;
	amountPredicate.rigthFieldID = @"100";
	[firstQuery addHasQueryPredicateObject:amountPredicate];

	NSError *error = nil;
	XCTAssertTrue([firstContext save:&error], @"save failed: %@", error);

	// SQL out of the model, through the generator the golden tests pin.
	self.dataDelegate.database = [MADMock mockDatabase];
	MADQueryFull *generator = [[MADQueryFull alloc] initWithQuery:firstQuery andQueryLimit:0];
	generator.dataDelegate = self.dataDelegate;
	NSString *generatedSQL = [generator SQLOnlyActiveFields:NO managedObjectContext:firstContext error:&error];
	XCTAssertNotNil(generatedSQL, @"%@", error);

	// The generated SQL into a fresh document, through the whole importer.
	MADHeadlessDocument *second = [self makeDocumentNamed:@"fixpoint-second.mad"];
	XCTAssertTrue([self applyStatement:generatedSQL toDocument:second error:&error], @"%@", error);

	// SQL out again -- the two statements are one string.
	self.dataDelegate.database = [MADMock mockDatabase];
	MADQueryFull *regenerated = [[MADQueryFull alloc] initWithQuery:[self queryOfDocument:second] andQueryLimit:0];
	regenerated.dataDelegate = self.dataDelegate;
	NSString *regeneratedSQL = [regenerated SQLOnlyActiveFields:NO managedObjectContext:second.storeContext error:&error];
	XCTAssertNotNil(regeneratedSQL, @"%@", error);
	XCTAssertEqualObjects(regeneratedSQL, generatedSQL);

	// And the document kept the entered text, verbatim.
	XCTAssertEqualObjects([self queryOfDocument:second].sqlSourceText, generatedSQL);
}

@end
