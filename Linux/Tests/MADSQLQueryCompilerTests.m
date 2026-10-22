//
//  MADSQLQueryCompilerTests.m
//  Linux/Tests
//
//  Ported from MADTests/MADSQLQueryCompilerTests.m: the pasted-SQL importer's
//  write half (MAD_SQL_ENTRY.md §6.3, §6.4, §10.4) -- the happy-path apply
//  builds the designer's rows and stores the entered text verbatim, the replace
//  path leaves no orphan, the conflict path aborts with the store untouched,
//  and the fixpoint round trip is the statement that defines the feature.
//
//  The document under test is MADHeadlessDocument, the Linux-side member of the
//  MADSQLQueryDocument pair: its helpers write the same definition rows
//  MADocument's write, so what is asserted here holds for the app's document
//  too.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import <MAD/MADSQLCompileError.h>
#import <MAD/MADSQLParser.h>
#import <MAD/MADSQLStatement.h>
#import <MAD/MADSQLStatementResolver.h>
#import <MAD/MADSQLQueryCompiler.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADQueryPredicate.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElementBarcode.h>

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

#pragma mark - The fixture

// A headless document over a fresh portable store, with the three schema tables
// the statements name: customers(id, name), invoices(id, customer_id, amount),
// lines(id, invoice_id, sku).  The document's guts directory is keyed by the
// file name in the shared temporary directory, so the name carries a UUID no
// earlier run can have used.
static void addSchemaTable(NSString *name, NSArray *fields, RptqDatabase *database, RptqStoreContext *context) {
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


static MADHeadlessDocument *makeDocument(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSString *unique = [[NSString alloc] initWithFormat:@"definition-%@.mad", [[NSUUID UUID] UUIDString]];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:unique]];

	MADHeadlessDocument *document = [[MADHeadlessDocument alloc] initWithFileURL:url];
	NSError *error = nil;
	MAD_PASS([document.documentStore openWithError:&error], "open failed: %s", [[error description] UTF8String]);

	RptqStoreContext *context = document.storeContext;
	RptqDocument *rptqDocument = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDatabase *database = (RptqDatabase *)[context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:20];
	[rptqDocument addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];

	addSchemaTable(@"customers", @[ @[ @"id", @(MADDataTypeInteger) ], @[ @"name", @(MADDataTypeString) ] ], database, context);
	addSchemaTable(@"invoices", @[ @[ @"id", @(MADDataTypeInteger) ], @[ @"customer_id", @(MADDataTypeInteger) ], @[ @"amount", @(MADDataTypeDecimal) ] ], database, context);
	addSchemaTable(@"lines", @[ @[ @"id", @(MADDataTypeInteger) ], @[ @"invoice_id", @(MADDataTypeInteger) ], @[ @"sku", @(MADDataTypeString) ] ], database, context);

	MAD_PASS([context save:&error], "save failed: %s", [[error description] UTF8String]);
	return document;
}

static RptqQuery *queryOfDocument(MADHeadlessDocument *document) {
	return document.activeDocumentModel.mainQuery;
}

// The parser's schema: table name -> field names, read off the document's own
// schema rows.
static NSDictionary *schemaDictionaryForDocument(MADHeadlessDocument *document) {
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
static BOOL applyStatement(NSString *sql, MADHeadlessDocument *document, NSError **error) {
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
									 identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													   schema:schemaDictionaryForDocument(document)];
	MADSQLStatement *statement = [parser parseStatement:error];
	if (statement == nil) return NO;

	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement
																				  database:document.activeDocumentModel.defaultDatabase];
	MADSQLQueryPlan *plan = [resolver resolveWithError:error];
	if (plan == nil) return NO;

	MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																	 document:document
																		query:queryOfDocument(document)
																	  context:document.storeContext];
	return [compiler applyWithError:error];
}

// The designer's add-table flow, for the fixtures the apply runs over: one
// query table (with a field per schema field) for the named schema table.
static RptqQueryTable *addQueryTable(NSString *name, RptqQuery *query, RptqDatabase *database, RptqStoreContext *context) {
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

static RptqQueryField *queryFieldNamed(NSString *name, RptqQueryTable *queryTable) {
	for (RptqQueryField *field in queryTable.hasQueryFields) {
		if ([field.databaseSchemaField.name isEqualToString:name]) return field;
	}
	return nil;
}

#pragma mark - Happy path

static void testHappyPathApplyBuildsTheDesignersRows(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqQuery *query = queryOfDocument(document);
	RptqStoreContext *context = document.storeContext;

	NSString *sql =
		@"SELECT customers.name, invoices.amount FROM customers INNER JOIN invoices "
		@"ON customers.id = invoices.customer_id WHERE invoices.amount > 100 "
		@"AND customers.name = 'A' GROUP BY customers.name ORDER BY customers.name DESC";
	NSError *error = nil;
	MAD_PASS(applyStatement(sql, document, &error), "the apply succeeds: %s", [[error description] UTF8String]);

	// Tables: one per plan table, with the right schema refs and copy index.
	MAD_PASS(query.hasQueryTables.count == (NSUInteger)2, "two query tables");
	RptqQueryTable *customersTable = nil;
	RptqQueryTable *invoicesTable = nil;
	for (RptqQueryTable *table in query.hasQueryTables) {
		if ([table.databaseSchemaTable.name isEqualToString:@"customers"]) customersTable = table;
		if ([table.databaseSchemaTable.name isEqualToString:@"invoices"]) invoicesTable = table;
	}
	MAD_PASS(customersTable != nil, "the customers table exists");
	MAD_PASS(invoicesTable != nil, "the invoices table exists");
	MAD_PASS(customersTable.dropIndex == 0, "the customers copy index");
	MAD_PASS(invoicesTable.dropIndex == 0, "the invoices copy index");

	// Fields: the add-table flow's one query field per schema field, wired up.
	MAD_PASS(customersTable.hasQueryFields.count == (NSUInteger)2, "customers has two query fields");
	MAD_PASS(invoicesTable.hasQueryFields.count == (NSUInteger)3, "invoices has three query fields");
	MAD_PASS([context objectsForEntity:@"RptqQueryField"].count == (NSUInteger)5, "five query fields, no more");
	for (RptqQueryField *field in customersTable.hasQueryFields) {
		MAD_PASS(field.inQueryTable == customersTable, "the field's table is wired");
		MAD_PASS_EQUAL(field.databaseSchemaField.inTable.name, @"customers", "the field's schema table");
	}

	// Links: the join type, the fields and the string IDs the factory writes.
	MAD_PASS(query.hasQueryLinks.count == (NSUInteger)1, "one link");
	RptqQueryLinks *link = query.hasQueryLinks.anyObject;
	MAD_PASS(link.type == (int16_t)MADLinkTypeInnerJoin, "the link type");
	MAD_PASS_EQUAL(link.hasLeftField.databaseSchemaField.name, @"id", "the link's left field");
	MAD_PASS_EQUAL(link.hasLeftField.inQueryTable.databaseSchemaTable.name, @"customers", "the link's left table");
	MAD_PASS_EQUAL(link.hasRightField.databaseSchemaField.name, @"customer_id", "the link's right field");
	MAD_PASS_EQUAL(link.hasRightField.inQueryTable.databaseSchemaTable.name, @"invoices", "the link's right table");
	MAD_PASS_EQUAL(link.fieldLeftID, @"id", "the link's left field id");
	MAD_PASS_EQUAL(link.tableLeftID, @"customers", "the link's left table id");
	MAD_PASS_EQUAL(link.fieldRightID, @"customer_id", "the link's right field id");
	MAD_PASS_EQUAL(link.tableRightID, @"invoices", "the link's right table id");

	// Predicates: the operator, the field, and the value string.
	MAD_PASS(query.hasQueryPredicate.count == (NSUInteger)2, "two predicates");
	RptqQueryPredicate *amountPredicate = nil;
	RptqQueryPredicate *namePredicate = nil;
	for (RptqQueryPredicate *predicate in query.hasQueryPredicate) {
		if (predicate.comparson == (int16_t)MADPredicateOperatorGreaterThan) amountPredicate = predicate;
		if (predicate.comparson == (int16_t)MADPredicateOperatorEqual) namePredicate = predicate;
	}
	MAD_PASS(amountPredicate != nil, "the amount predicate exists");
	MAD_PASS_EQUAL(amountPredicate.hasLeftField.databaseSchemaField.name, @"amount", "the amount predicate's field");
	MAD_PASS_EQUAL(amountPredicate.rigthFieldID, @"100", "the amount predicate's value");
	MAD_PASS(namePredicate != nil, "the name predicate exists");
	MAD_PASS_EQUAL(namePredicate.hasLeftField.databaseSchemaField.name, @"name", "the name predicate's field");
	MAD_PASS_EQUAL(namePredicate.rigthFieldID, @"A", "the name predicate's value");

	// Groups: the row, its sort and weight, and the report's header and footer
	// sections with their rows.
	MAD_PASS(query.hasQueryGroups.count == (NSUInteger)1, "one group");
	RptqQueryGroup *group = query.hasQueryGroups.anyObject;
	MAD_PASS_EQUAL(group.hasField.databaseSchemaField.name, @"name", "the group's field");
	MAD_PASS(group.sort == (int16_t)MADSortOrderDecending, "the group's sort");
	// The group factory weights the first group 1 (lastWeight + 1, the same
	// arithmetic the designer's own path uses).
	MAD_PASS(group.weight == (int16_t)1, "the group's weight");
	MAD_PASS(group.hasSection.count == (NSUInteger)2, "the group's two sections");
	RptqDocumentSection *header = nil;
	RptqDocumentSection *footer = nil;
	for (RptqDocumentSection *section in group.hasSection) {
		if (section.type == (int16_t)MADDocumentSectionTypeGroupHeader) header = section;
		if (section.type == (int16_t)MADDocumentSectionTypeGroupFooter) footer = section;
	}
	MAD_PASS(header != nil, "the group header exists");
	MAD_PASS(footer != nil, "the group footer exists");
	MAD_PASS(header.inGroup == group, "the header's group is wired");
	MAD_PASS(footer.inGroup == group, "the footer's group is wired");
	MAD_PASS(header.hasRows.count == (NSUInteger)1, "the header's row");
	MAD_PASS(footer.hasRows.count == (NSUInteger)1, "the footer's row");

	// The entered text is part of the document, verbatim.
	MAD_PASS_EQUAL(query.sqlSourceText, sql, "the entered text is stored verbatim");

	// One save: everything above survives a close and reopen.
	[document.documentStore close];
	error = nil;
	MAD_PASS([document.documentStore openWithError:&error], "reopen failed: %s", [[error description] UTF8String]);
	MAD_PASS_EQUAL(queryOfDocument(document).sqlSourceText, sql, "the entered text survives the reopen");
	MAD_PASS(queryOfDocument(document).hasQueryTables.count == (NSUInteger)2, "the tables survive the reopen");
	MAD_PASS(queryOfDocument(document).hasQueryPredicate.count == (NSUInteger)2, "the predicates survive the reopen");
	MAD_PASS(queryOfDocument(document).hasQueryGroups.count == (NSUInteger)1, "the group survives the reopen");
}

#pragma mark - Replace path

static void testApplyOverAPopulatedQueryReplacesItWithoutOrphans(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	// The existing query: customers and lines, a link, a predicate, a group.
	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *customersID = queryFieldNamed(@"id", customersTable);
	RptqQueryField *linesInvoiceID = queryFieldNamed(@"invoice_id", linesTable);
	RptqQueryLinks *oldLink = [RptqQueryLinks newQueryLinksWithLeftField:customersID rightField:linesInvoiceID joinType:MADLinkTypeInnerJoin managedObjectContext:context];
	[query addHasQueryLinksObject:oldLink];

	RptqQueryField *customersName = queryFieldNamed(@"name", customersTable);
	RptqQueryPredicate *oldPredicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	oldPredicate.comparson = (int16_t)MADPredicateOperatorEqual;
	oldPredicate.hasLeftField = customersName;
	oldPredicate.rigthFieldID = @"Old";
	[query addHasQueryPredicateObject:oldPredicate];

	[document addQueryGroupWithQueryField:customersName.identifier andSortOrder:MADSortOrderAccending];
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	// The apply: customers joins invoices; lines is dropped, everything else
	// replaced.
	NSString *sql = @"SELECT customers.name, invoices.amount FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id WHERE invoices.amount >= 5";
	NSError *error = nil;
	MAD_PASS(applyStatement(sql, document, &error), "the apply succeeds: %s", [[error description] UTF8String]);

	MAD_PASS([context objectsForEntity:@"RptqQueryTable"].count == (NSUInteger)2, "two query tables remain");
	MAD_PASS([context objectsForEntity:@"RptqQueryField"].count == (NSUInteger)5, "five query fields, the dropped table's included in none");
	MAD_PASS([context objectsForEntity:@"RptqQueryLinks"].count == (NSUInteger)1, "one link remains");
	MAD_PASS([context objectsForEntity:@"RptqQueryPredicate"].count == (NSUInteger)1, "one predicate remains");
	MAD_PASS([context objectsForEntity:@"RptqQueryGroup"].count == (NSUInteger)0, "no group remains");

	RptqQueryLinks *link = query.hasQueryLinks.anyObject;
	MAD_PASS_EQUAL(link.hasLeftField.inQueryTable.databaseSchemaTable.name, @"customers", "the new link's left table");
	MAD_PASS_EQUAL(link.hasRightField.inQueryTable.databaseSchemaTable.name, @"invoices", "the new link's right table");

	RptqQueryPredicate *predicate = query.hasQueryPredicate.anyObject;
	MAD_PASS(predicate.comparson == (int16_t)MADPredicateOperatorGreaterThanOrEqualTo, "the new predicate's operator");
	MAD_PASS_EQUAL(predicate.rigthFieldID, @"5", "the new predicate's value");

	for (RptqQueryTable *table in query.hasQueryTables) {
		MAD_PASS(![table.databaseSchemaTable.name isEqualToString:@"lines"], "the dropped table is gone");
	}

	MAD_PASS_EQUAL(query.sqlSourceText, sql, "the entered text is replaced");
}

#pragma mark - Conflict path

static void buildConflictingElement(Class elementClass, RptqQueryField *field, MADHeadlessDocument *document) {
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

static void assertApplyFailsWithDesignerConflict(MADHeadlessDocument *document, NSString *sql) {
	// The before snapshot: everything the store holds, including the previous
	// entered text.
	RptqQuery *query = queryOfDocument(document);
	query.sqlSourceText = @"PREVIOUS TEXT";
	NSError *saveError = nil;
	MAD_PASS([document.storeContext save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	MADStoreGraph *before = [document.storeContext.store allObjectsWithError:&saveError];
	MAD_PASS(before != nil, "%s", [[saveError description] UTF8String]);

	NSError *error = nil;
	MAD_PASS(!applyStatement(sql, document, &error), "the apply fails");
	MAD_PASS(error != nil, "the apply reports an error");
	if (error == nil) return;
	MAD_PASS(error.code == (NSInteger)MADSQLCompileErrorDesignerConflict, "the conflict code: %s", [[error description] UTF8String]);
	MAD_PASS_EQUAL(error.domain, MADSQLCompileErrorDomain, "the error domain");
	MAD_PASS(error.userInfo[NSLocalizedDescriptionKey] != nil, "the error names the elements");

	// Nothing changed: not the rows, not the entered text.
	MAD_PASS_EQUAL(queryOfDocument(document).sqlSourceText, @"PREVIOUS TEXT", "the previous text stands");
	MADStoreGraph *after = [document.storeContext.store allObjectsWithError:&saveError];
	MAD_PASS(after != nil, "%s", [[saveError description] UTF8String]);
	MAD_PASS([after isEqualToGraph:before], "the failed apply changed the store");
}

static void testALabelDataElementOnADroppedTableBlocksTheApply(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *linesSKU = queryFieldNamed(@"sku", linesTable);
	buildConflictingElement([RptqDocumentElementLabelDataField class], linesSKU, document);
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	assertApplyFailsWithDesignerConflict(document, @"SELECT customers.name FROM customers");
}

static void testAnAggregateElementOnADroppedTableBlocksTheApply(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *linesID = queryFieldNamed(@"id", linesTable);
	buildConflictingElement([RptqDocumentElementAggregate class], linesID, document);
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	assertApplyFailsWithDesignerConflict(document, @"SELECT customers.name FROM customers");
}

static void testABarcodeElementOnADroppedTableBlocksTheApply(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *linesSKU = queryFieldNamed(@"sku", linesTable);
	buildConflictingElement([RptqDocumentElementBarcode class], linesSKU, document);
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	assertApplyFailsWithDesignerConflict(document, @"SELECT customers.name FROM customers");
}

static void testAGroupOnADroppedTableBlocksTheApply(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *linesSKU = queryFieldNamed(@"sku", linesTable);
	[document addQueryGroupWithQueryField:linesSKU.identifier andSortOrder:MADSortOrderAccending];
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	assertApplyFailsWithDesignerConflict(document, @"SELECT customers.name FROM customers");
}

static void testAnElementOnAKeptTableDoesNotBlockTheApply(void) {
	MADHeadlessDocument *document = makeDocument();
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = queryOfDocument(document);
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", query, database, context);
	RptqQueryTable *linesTable = addQueryTable(@"lines", query, database, context);
	RptqQueryField *customersName = queryFieldNamed(@"name", customersTable);
	buildConflictingElement([RptqDocumentElementLabelDataField class], customersName, document);
	NSError *saveError = nil;
	MAD_PASS([context save:&saveError], "save failed: %s", [[saveError description] UTF8String]);

	// customers is kept, so the designer's element survives the apply.
	NSError *error = nil;
	MAD_PASS(applyStatement(@"SELECT customers.name FROM customers", document, &error),
			 "the apply succeeds: %s", [[error description] UTF8String]);
	MAD_PASS([context objectsForEntity:@"RptqDocumentElementLabelDataField"].count == (NSUInteger)1,
			 "the designer's element survives");
}

#pragma mark - The fixpoint

static void testFixpointRoundTrip(void) {
	// The model, built through the designer's own factories.
	MADHeadlessDocument *first = makeDocument();
	RptqStoreContext *firstContext = first.storeContext;
	RptqQuery *firstQuery = queryOfDocument(first);
	RptqDatabase *firstDatabase = first.activeDocumentModel.defaultDatabase;

	RptqQueryTable *customersTable = addQueryTable(@"customers", firstQuery, firstDatabase, firstContext);
	RptqQueryTable *invoicesTable = addQueryTable(@"invoices", firstQuery, firstDatabase, firstContext);

	RptqQueryField *customersID = queryFieldNamed(@"id", customersTable);
	RptqQueryField *invoicesCustomerID = queryFieldNamed(@"customer_id", invoicesTable);
	RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField:customersID rightField:invoicesCustomerID joinType:MADLinkTypeInnerJoin managedObjectContext:firstContext];
	[firstQuery addHasQueryLinksObject:link];

	RptqQueryField *customersName = queryFieldNamed(@"name", customersTable);
	RptqQueryPredicate *namePredicate = (RptqQueryPredicate *)[firstContext insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	namePredicate.comparson = (int16_t)MADPredicateOperatorEqual;
	namePredicate.hasLeftField = customersName;
	namePredicate.rigthFieldID = @"O'Brien";
	[firstQuery addHasQueryPredicateObject:namePredicate];

	// One predicate: the WHERE clause iterates the predicate set, whose order
	// is the set's (unpinned everywhere else, and GNUstep's differs from
	// Apple's), so the fixpoint keeps the clause to a single member.  The
	// quoted literal is the stronger case anyway -- it round-trips through the
	// generator's quote-doubling.
	NSError *error = nil;
	MAD_PASS([firstContext save:&error], "save failed: %s", [[error description] UTF8String]);

	// SQL out of the model, through the generator the golden tests pin.
	MADSQLTestDataDelegate *dataDelegate = [[MADSQLTestDataDelegate alloc] init];
	dataDelegate.database = [MADMock mockDatabase];
	MADQueryFull *generator = [[MADQueryFull alloc] initWithQuery:firstQuery andQueryLimit:0];
	generator.dataDelegate = dataDelegate;
	NSString *generatedSQL = [generator SQLOnlyActiveFields:NO managedObjectContext:firstContext error:&error];
	MAD_PASS(generatedSQL != nil, "%s", [[error description] UTF8String]);

	// The generated SQL into a fresh document, through the whole importer.
	MADHeadlessDocument *second = makeDocument();
	MAD_PASS(applyStatement(generatedSQL, second, &error), "the apply succeeds: %s", [[error description] UTF8String]);

	// SQL out again -- the two statements are one string.
	MADQueryFull *regenerated = [[MADQueryFull alloc] initWithQuery:queryOfDocument(second) andQueryLimit:0];
	regenerated.dataDelegate = dataDelegate;
	NSString *regeneratedSQL = [regenerated SQLOnlyActiveFields:NO managedObjectContext:second.storeContext error:&error];
	MAD_PASS(regeneratedSQL != nil, "%s", [[error description] UTF8String]);
	MAD_PASS_EQUAL(regeneratedSQL, generatedSQL, "the round trip is a fixpoint");

	// And the document kept the entered text, verbatim.
	MAD_PASS_EQUAL(queryOfDocument(second).sqlSourceText, generatedSQL, "the entered text is stored verbatim");
}

MAD_TEST_MAIN("MADSQLQueryCompilerTests",
	MAD_TEST(testHappyPathApplyBuildsTheDesignersRows),
	MAD_TEST(testApplyOverAPopulatedQueryReplacesItWithoutOrphans),
	MAD_TEST(testALabelDataElementOnADroppedTableBlocksTheApply),
	MAD_TEST(testAnAggregateElementOnADroppedTableBlocksTheApply),
	MAD_TEST(testABarcodeElementOnADroppedTableBlocksTheApply),
	MAD_TEST(testAGroupOnADroppedTableBlocksTheApply),
	MAD_TEST(testAnElementOnAKeptTableDoesNotBlockTheApply),
	MAD_TEST(testFixpointRoundTrip));
