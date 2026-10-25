//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADStoreTests.m
//  Linux/Tests
//
//  Ported from MADTests/MADStoreTests.m: coverage for the portable store -- the
//  schema descriptors, and a headless round trip of a document definition through
//  a real SQLite file.  The Xcode setUp/tearDown pair is a fresh temp directory per
//  test here.
//
//  The original's last section cross-checks the descriptors against Core Data's
//  compiled model (MAD.momd).  Core Data does not exist off Apple and the Linux
//  subset carries no model, so that one test reports a need; its Core Data-only
//  helpers (the rename/expansion/transform maps and the NSAttributeType mapping)
//  had no other caller and stay on the Xcode side.
//

#import "MADTestSupport.h"

#import <MAD/MADStoreSchema.h>
#import <MAD/MADStoreObject.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStore.h>

#pragma mark - Fixture helpers

static MADStoreObject *Object(NSString *entity, int64_t identifier) {
	return [MADStoreObject objectWithEntity:entity identifier:identifier];
}

static void SetValue(MADStoreObject *object, NSString *name, id value) {
	[object setAttributeValue:value forName:name];
}

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

// Stands in for the Xcode suite's -setUp: an open store over
// <directory>/definition.sqlite.
static MADStore *makeOpenStore(NSURL *url) {
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "open failed: %s", [[error description] UTF8String]);
	return store;
}

// Stands in for the Xcode suite's -tearDown: close, then drop the directory.
static void closeAndRemove(MADStore *store, NSURL *directory) {
	[store close];
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

#pragma mark - The fixture

/// A document with a detail section and a report header, elements with their value
/// satellites, a database with a table of three fields, and a query that selects
/// two of those fields in an order of its own.  Between them the fixture covers
/// every column type, all four ordered relationships, the one many-to-many, and
/// both shared-table and satellite rows.
static MADStoreGraph *fixtureGraph(void) {
	MADStoreGraph *graph = [MADStoreGraph new];

	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"papersize", @3);
	[graph addObject:document];

	MADStoreObject *database = Object(@"RptqDatabase", 10);
	SetValue(database, @"databaseDriverType", @"MySQL");
	SetValue(database, @"databaseDriverTypeEnum", @2);
	[database setReference:@1 forName:@"ownedByQueryAsStaticResource"];
	[graph addObject:database];

	MADStoreObject *table = Object(@"RptqDatabaseSchemaTable", 11);
	SetValue(table, @"name", @"customers");
	SetValue(table, @"queryable", @1);
	[table setReference:@10 forName:@"inDatabase"];
	[graph addObject:table];

	MADStoreObject *idField = Object(@"RptqDatabaseSchemaField", 12);
	SetValue(idField, @"name", @"id");
	SetValue(idField, @"primaryKey", @1);
	SetValue(idField, @"dataType", @1);
	SetValue(idField, @"decimals", @0);
	SetValue(idField, @"width", @11);
	[idField setReference:@11 forName:@"inTable"];
	[graph addObject:idField];

	MADStoreObject *nameField = Object(@"RptqDatabaseSchemaField", 13);
	SetValue(nameField, @"name", @"name");
	SetValue(nameField, @"width", @64);
	[nameField setReference:@11 forName:@"inTable"];
	[graph addObject:nameField];

	MADStoreObject *emailField = Object(@"RptqDatabaseSchemaField", 14);
	SetValue(emailField, @"name", @"email");
	[emailField setReference:@11 forName:@"inTable"];
	[graph addObject:emailField];

	// Fields are listed out of the order the reader would sort them in, so the
	// `position` column is what the round trip has to reproduce.
	[[table collectionForName:@"hasFields"] addObjectsFromArray:@[ @13, @14, @12 ]];

	MADStoreObject *query = Object(@"RptqQuery", 20);
	SetValue(query, @"override", @0);
	SetValue(query, @"cachedText", @"SELECT ...");
	[query setReference:@10 forName:@"inDatabase"];
	[[query collectionForName:@"hasFields"] addObjectsFromArray:@[ @12, @13 ]];
	[graph addObject:query];

	MADStoreObject *queryTable = Object(@"RptqQueryTable", 21);
	SetValue(queryTable, @"alias", @"c");
	SetValue(queryTable, @"dropIndex", @0);
	[queryTable setReference:@11 forName:@"databaseSchemaTable"];
	[queryTable setReference:@20 forName:@"inQuery"];
	[graph addObject:queryTable];
	[[table collectionForName:@"inQueryTable"] addObject:@21];

	MADStoreObject *queryField = Object(@"RptqQueryField", 22);
	[queryField setReference:@21 forName:@"inQueryTable"];
	[queryField setReference:@12 forName:@"databaseSchemaField"];
	[graph addObject:queryField];

	// Layout: a detail section holding two rows, and a report header with none.
	MADStoreObject *detail = Object(@"RptqDocumentSection", 30);
	SetValue(detail, @"numberOfRows", @2);
	SetValue(detail, @"type", @1);
	SetValue(detail, @"height", @44.5);
	SetValue(detail, @"layoutHeight", @88.25);
	[detail setReference:@1 forName:@"inReport"];
	[graph addObject:detail];

	MADStoreObject *header = Object(@"RptqDocumentSection", 31);
	SetValue(header, @"numberOfRows", @0);
	[header setReference:@1 forName:@"inReportReportHeader"];
	[graph addObject:header];

	MADStoreObject *firstRow = Object(@"RptqDocumentSectionRows", 40);
	SetValue(firstRow, @"rowNumber", @1);
	SetValue(firstRow, @"layoutHeight", @22.5);
	[firstRow setReference:@30 forName:@"inSection"];
	[graph addObject:firstRow];

	MADStoreObject *secondRow = Object(@"RptqDocumentSectionRows", 41);
	SetValue(secondRow, @"rowNumber", @2);
	[secondRow setReference:@30 forName:@"inSection"];
	[graph addObject:secondRow];

	// Second row first, again so the order cannot come from the identifier.
	[[detail collectionForName:@"hasRows"] addObjectsFromArray:@[ @41, @40 ]];

	MADStoreObject *label = Object(@"RptqDocumentElementLabel", 50);
	SetValue(label, @"text", @"Hello, world");
	SetValue(label, @"fontsize", @12.5);
	SetValue(label, @"fontname", @"Helvetica");
	SetValue(label, @"backgroundColorR", @1.0);
	SetValue(label, @"backgroundColorG", @0.5);
	SetValue(label, @"backgroundColorB", @0.25);
	SetValue(label, @"backgroundColorA", @0.75);
	[label setReference:@40 forName:@"inSectionRow"];
	[graph addObject:label];

	MADStoreObject *image = Object(@"RptqDocumentElementImage", 51);
	SetValue(image, @"image", [@"PNG-ish bytes" dataUsingEncoding:NSUTF8StringEncoding]);
	[image setReference:@41 forName:@"inSectionRow"];
	[graph addObject:image];

	// The element satellites: a rect with an origin and a size, an alignment, a
	// numeric format, and padding.
	MADStoreObject *rect = Object(@"RptqRect", 60);
	[rect setReference:@50 forName:@"inElement"];
	[graph addObject:rect];

	MADStoreObject *point = Object(@"RptqPoint", 61);
	SetValue(point, @"x", @1.5);
	SetValue(point, @"y", @2.25);
	[point setReference:@60 forName:@"inRect"];
	[graph addObject:point];

	MADStoreObject *size = Object(@"RptqSize", 62);
	SetValue(size, @"width", @100.0);
	SetValue(size, @"height", @20.5);
	[size setReference:@60 forName:@"inRect"];
	[graph addObject:size];

	MADStoreObject *alignment = Object(@"RptqAlignment", 63);
	SetValue(alignment, @"horizontal", @1);
	SetValue(alignment, @"vertical", @2);
	[alignment setReference:@50 forName:@"inElement"];
	[graph addObject:alignment];

	MADStoreObject *numericFormat = Object(@"RptqNumericFormat", 64);
	SetValue(numericFormat, @"locale", @"en_US");
	SetValue(numericFormat, @"enabled", @1);
	SetValue(numericFormat, @"decimalCount", @2);
	[numericFormat setReference:@50 forName:@"inElement"];
	[graph addObject:numericFormat];

	MADStoreObject *padding = Object(@"RptqDirectionalAsymmetry", 65);
	SetValue(padding, @"top", @1.0);
	SetValue(padding, @"bottom", @2.0);
	SetValue(padding, @"left", @3.0);
	SetValue(padding, @"right", @4.0);
	[padding setReference:@50 forName:@"inElementPadding"];
	[graph addObject:padding];

	return graph;
}

static MADStoreGraph *writeAndReadFixture(MADStore *store) {
	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "write failed: %s", [[error description] UTF8String]);
	MADStoreGraph *read = [store allObjectsWithError:&error];
	MAD_PASS(read != nil, "read failed: %s", [[error description] UTF8String]);
	return read;
}

static void assertGraph(MADStoreGraph *actual, MADStoreGraph *expected) {
	MAD_PASS(actual.count == expected.count, "object count");
	for (MADStoreObject *object in [expected allObjects]) {
		MADStoreObject *other = [actual objectForEntity:object.entity identifier:object.identifier];
		if (!other) {
			MAD_PASS(NO, "missing %s %lld", object.entity.UTF8String, (long long)object.identifier);
			continue;
		}
		if (![object isEqualToObject:other]) {
			MAD_PASS(NO, "%s %lld: expected %s, actual %s",
					 object.entity.UTF8String, (long long)object.identifier,
					 [[object description] UTF8String], [[other description] UTF8String]);
		}
	}
}

#pragma mark - Schema

static void testSchemaCoversEveryEntityOnce(void) {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MAD_PASS(schema.entities.count == (NSUInteger)33, "the schema holds 33 entities");
	MAD_PASS(schema.tables.count == (NSUInteger)24, "the schema holds 24 tables");

	NSMutableSet<NSString *> *names = [NSMutableSet set];
	for (MADStoreEntity *entity in schema.entities) {
		MAD_PASS(![names containsObject:entity.name], "duplicate %s", entity.name.UTF8String);
		[names addObject:entity.name];
		MAD_PASS(entity.table != nil, "every entity resolves a table");
	}
	MAD_PASS(names.count == (NSUInteger)33, "every entity name is distinct");
}

static void testSubentitiesShareTheElementTable(void) {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MADStoreEntity *element = [schema entityNamed:@"RptqDocumentElement"];
	MAD_PASS(element != nil, "the base element entity exists");
	MAD_PASS(element.subentities.count == (NSUInteger)9, "the base element has nine subentities");
	MAD_PASS(!element.isSubentity, "the base element is not itself a subentity");

	for (MADStoreEntity *subentity in element.subentities) {
		MAD_PASS(subentity.isSubentity, "the child is a subentity");
		MAD_PASS_EQUAL(subentity.table, @"RptqDocumentElement", "a subentity shares the base's table");
		// The base's attributes and edges are inherited, not repeated.
		MAD_PASS(subentity.allAttributes.count == element.attributes.count + subentity.attributes.count,
				 "allAttributes is the base's attributes plus the child's own");
		MAD_PASS([subentity anyRelationshipNamed:@"inSectionRow"] != nil, "the child inherits the base's edges");
	}
}

/// The `position` column sits on the child table, next to the foreign key that
/// points back at the parent -- one column per child, not one per relationship.
static void testPositionColumnsLandOnTheChildTable(void) {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSMutableSet<NSString *> *positioned = [NSMutableSet set];
	for (MADStoreEntity *table in schema.tables) {
		if (table.hasPositionColumn) [positioned addObject:table.name];
	}
	NSSet *expected = [NSSet setWithObjects:@"RptqDatabaseSchemaField", @"RptqQueryTable",
					   @"RptqDocumentSectionRows", @"RptqDocumentElement", nil];
	MAD_PASS_EQUAL(positioned, expected, "the position columns land on the child tables");
}

static void testSchemaSQLCreatesEveryTableOnce(void) {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSString *sql = schema.createSchemaSQL;
	for (MADStoreEntity *table in schema.tables) {
		NSString *statement = [[NSString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS \"%@\"", table.name];
		NSRange range = [sql rangeOfString:statement];
		MAD_PASS(range.location != (NSUInteger)NSNotFound, "no table for %s", table.name.UTF8String);
		NSRange rest = NSMakeRange(range.location + 1, sql.length - range.location - 1);
		MAD_PASS([sql rangeOfString:statement options:0 range:rest].location == (NSUInteger)NSNotFound,
				 "%s created twice", table.name.UTF8String);
	}
	MAD_PASS([sql rangeOfString:@"\"RptqQueryHasFields\""].location != (NSUInteger)NSNotFound,
			 "the many-to-many join table is created");
}

#pragma mark - Round trip

static void testRoundTripOfAWholeDefinition(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreGraph *expected = [fixtureGraph() graphByCompletingInverses];
	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "write failed: %s", [[error description] UTF8String]);

	MADStoreGraph *actual = [store allObjectsWithError:&error];
	MAD_PASS(actual != nil, "read failed: %s", [[error description] UTF8String]);
	assertGraph(actual, expected);

	closeAndRemove(store, directory);
}

static void testRoundTripIsStableAcrossASecondWrite(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreGraph *first = writeAndReadFixture(store);

	// Writing back what was read is what a save after an edit looks like.  It must
	// not duplicate a row or drop an edge.
	NSError *error = nil;
	MAD_PASS([store writeGraph:first replacingAll:YES error:&error], "rewrite failed: %s", [[error description] UTF8String]);
	MADStoreGraph *second = [store allObjectsWithError:&error];
	MAD_PASS(second != nil, "reread failed: %s", [[error description] UTF8String]);
	assertGraph(second, first);

	closeAndRemove(store, directory);
}

static void testFetchByIdentifier(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "the fixture writes");

	MADStoreObject *table = [store objectForEntity:@"RptqDatabaseSchemaTable" identifier:11 error:&error];
	MAD_PASS(table != nil, "the table row is fetched");
	MAD_PASS_EQUAL([table attributeValue:@"name"], @"customers", "the name attribute reads back");
	MAD_PASS_EQUAL([table referenceForName:@"inDatabase"], @10, "the to-one edge reads back");
	// A flat read carries no edges beyond the ones this row owns.
	MAD_PASS([table existingCollectionForName:@"hasFields"] == nil, "a flat read carries no to-many edge");

	MADStoreObject *element = [store objectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error];
	MAD_PASS(element != nil, "a subentity is addressed by its own name");
	MAD_PASS_EQUAL([element attributeValue:@"text"], @"Hello, world", "the label text reads back");
	MAD_PASS_EQUAL([element referenceForName:@"inSectionRow"], @40, "the label's row edge reads back");

	// The same identifier under a sibling kind is a different row, and is not there.
	MAD_PASS([store objectForEntity:@"RptqDocumentElementImage" identifier:50 error:&error] == nil,
			 "a sibling kind's row is not under this identifier");

	closeAndRemove(store, directory);
}

static void testFetchUnknownEntityAndMissingRow(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store objectForEntity:@"RptqNonesuch" identifier:1 error:&error] == nil, "an unknown entity fetches nothing");
	MAD_PASS(error.code == MADStoreErrorUnknownEntity, "the error names the unknown entity");

	error = nil;
	MAD_PASS([store objectForEntity:@"RptqDocument" identifier:999 error:&error] == nil, "an absent row fetches nothing");
	MAD_PASS(error == nil, "an absent row is not an error");

	closeAndRemove(store, directory);
}

static void testFetchByPart(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "the fixture writes");

	// The database, its table, and the table's three fields.
	MADStoreGraph *schema = [store graphForPart:MADStorePartSchema error:&error];
	MAD_PASS(schema != nil, "the schema part reads");
	MAD_PASS(schema.count == (NSUInteger)5, "the schema part holds five rows");
	MAD_PASS([schema objectForEntity:@"RptqDatabaseSchemaTable" identifier:11] != nil, "the table is in the schema part");
	MAD_PASS([schema objectForEntity:@"RptqDocument" identifier:1] == nil, "the document is not in the schema part");

	// The query, its table reference, and its field reference.
	MADStoreGraph *query = [store graphForPart:MADStorePartQuery error:&error];
	MAD_PASS(query.count == (NSUInteger)3, "the query part holds three rows");
	MAD_PASS([query objectForEntity:@"RptqQuery" identifier:20] != nil, "the query is in the query part");

	// Everything the designer draws.
	MADStoreGraph *layout = [store graphForPart:MADStorePartLayout error:&error];
	MAD_PASS([layout objectForEntity:@"RptqDocument" identifier:1] != nil, "the document is in the layout part");
	MAD_PASS([layout objectForEntity:@"RptqDocumentElementLabel" identifier:50] != nil, "the label is in the layout part");
	MAD_PASS([layout objectForEntity:@"RptqDatabase" identifier:10] == nil, "the database is not in the layout part");

	closeAndRemove(store, directory);
}

static void testOrderedRelationshipsKeepTheirOrder(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);
	MADStoreGraph *graph = writeAndReadFixture(store);

	MADStoreObject *table = [graph objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	MAD_PASS_EQUAL([table existingCollectionForName:@"hasFields"], (@[ @13, @14, @12 ]),
				   "the table's fields keep the order they were given in");

	MADStoreObject *detail = [graph objectForEntity:@"RptqDocumentSection" identifier:30];
	MAD_PASS_EQUAL([detail existingCollectionForName:@"hasRows"], (@[ @41, @40 ]),
				   "the detail section's rows keep the order they were given in");

	MADStoreObject *secondRow = [graph objectForEntity:@"RptqDocumentSectionRows" identifier:41];
	MAD_PASS_EQUAL([secondRow existingCollectionForName:@"hasObjects"], (@[ @51 ]),
				   "the second row holds the image");

	MADStoreObject *firstRow = [graph objectForEntity:@"RptqDocumentSectionRows" identifier:40];
	MAD_PASS_EQUAL([firstRow existingCollectionForName:@"hasObjects"], (@[ @50 ]),
				   "the first row holds the label");

	// A section with no rows has an empty edge, not a missing one.
	MADStoreObject *header = [graph objectForEntity:@"RptqDocumentSection" identifier:31];
	MAD_PASS([header existingCollectionForName:@"hasRows"].count == (NSUInteger)0,
			 "a section with no rows has an empty edge, not a missing one");

	closeAndRemove(store, directory);
}

static void testManyToManySurvivesTheJoinTable(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);
	MADStoreGraph *graph = writeAndReadFixture(store);

	MADStoreObject *query = [graph objectForEntity:@"RptqQuery" identifier:20];
	MAD_PASS_EQUAL([query existingCollectionForName:@"hasFields"], (@[ @12, @13 ]),
				   "the query's fields survive the join table");

	for (NSNumber *identifier in @[ @12, @13 ]) {
		MADStoreObject *field = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:identifier.longLongValue];
		MAD_PASS_EQUAL([field existingCollectionForName:@"inQuery"], (@[ @20 ]),
					   "the selected field points back at the query");
	}

	// The field the query does not select is in no join row.
	MADStoreObject *emailField = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:14];
	MAD_PASS([emailField existingCollectionForName:@"inQuery"].count == (NSUInteger)0,
			 "the field the query does not select is in no join row");

	closeAndRemove(store, directory);
}

static void testDerivedToOneEdgesComeBackFromTheOwningSide(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);
	MADStoreGraph *graph = writeAndReadFixture(store);

	// RptqDocument owns no foreign key; its sections are found through theirs.
	MADStoreObject *document = [graph objectForEntity:@"RptqDocument" identifier:1];
	MAD_PASS_EQUAL([document referenceForName:@"hasDetailSection"], @30, "the detail section is found through its own key");
	MAD_PASS_EQUAL([document referenceForName:@"hasReportHeaderSection"], @31, "the report header is found through its own key");
	MAD_PASS([document referenceForName:@"hasPageHeaderSection"] == nil, "there is no page header section");

	MADStoreObject *label = [graph objectForEntity:@"RptqDocumentElementLabel" identifier:50];
	MAD_PASS_EQUAL([label referenceForName:@"rect"], @60, "the label's rect");
	MAD_PASS_EQUAL([label referenceForName:@"alignment"], @63, "the label's alignment");
	MAD_PASS_EQUAL([label referenceForName:@"numericFormat"], @64, "the label's numeric format");
	MAD_PASS_EQUAL([label referenceForName:@"padding"], @65, "the label's padding");

	// And the far side of each pair is filled in too.
	MADStoreObject *rect = [graph objectForEntity:@"RptqRect" identifier:60];
	MAD_PASS_EQUAL([rect referenceForName:@"inElement"], @50, "the rect's element");
	MAD_PASS_EQUAL([rect referenceForName:@"origin"], @61, "the rect's origin");
	MAD_PASS_EQUAL([rect referenceForName:@"size"], @62, "the rect's size");

	closeAndRemove(store, directory);
}

static void testAttributeValueTypesSurvive(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);
	MADStoreGraph *graph = writeAndReadFixture(store);

	MADStoreObject *label = [graph objectForEntity:@"RptqDocumentElementLabel" identifier:50];
	MAD_PASS_EQUAL([label attributeValue:@"fontsize"], @12.5, "the real font size survives");
	MAD_PASS_EQUAL([label attributeValue:@"backgroundColorG"], @0.5, "the real colour component survives");

	MADStoreObject *image = [graph objectForEntity:@"RptqDocumentElementImage" identifier:51];
	MAD_PASS_EQUAL([image attributeValue:@"image"], [@"PNG-ish bytes" dataUsingEncoding:NSUTF8StringEncoding],
				   "the blob attribute survives");

	MADStoreObject *format = [graph objectForEntity:@"RptqNumericFormat" identifier:64];
	MAD_PASS_EQUAL([format attributeValue:@"locale"], @"en_US", "the text attribute survives");

	// An attribute left unset comes back absent, not as a null.
	MADStoreObject *nameField = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:13];
	MAD_PASS([nameField attributeValue:@"decimals"] == nil, "an unset attribute reads back absent");
	MAD_PASS([nameField attributeValue:@"primaryKey"] == nil, "another unset attribute reads back absent");
	MAD_PASS(nameField.values.count == (NSUInteger)2, "only the two set values are present");

	closeAndRemove(store, directory);
}

#pragma mark - Writing

static void testSatelliteWithoutAModelIdentifierGetsASurrogate(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreObject *alignment = Object(@"RptqAlignment", 0);
	SetValue(alignment, @"horizontal", @1);
	SetValue(alignment, @"vertical", @3);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:alignment];

	NSError *error = nil;
	MAD_PASS([store writeGraph:graph error:&error], "write failed: %s", [[error description] UTF8String]);

	NSArray<MADStoreObject *> *rows = [store objectsForEntity:@"RptqAlignment" error:&error];
	MAD_PASS(rows.count == (NSUInteger)1, "one alignment row exists");
	MAD_PASS(rows.firstObject.identifier > (int64_t)0, "the row was given a positive surrogate");
	MAD_PASS_EQUAL([rows.firstObject attributeValue:@"vertical"], @3, "the value survives the surrogate write");

	closeAndRemove(store, directory);
}

/// A surrogate is allocated past whatever the table already holds, so a second
/// write cannot land on a row that is already there.
static void testSurrogateIsAllocatedPastTheRowsAlreadyThere(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreObject *first = Object(@"RptqAlignment", 7);
	SetValue(first, @"horizontal", @1);
	SetValue(first, @"vertical", @1);
	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:first];
	NSError *error = nil;
	MAD_PASS([store writeGraph:graph error:&error], "the first write succeeds");

	MADStoreObject *second = Object(@"RptqAlignment", 0);
	SetValue(second, @"horizontal", @2);
	SetValue(second, @"vertical", @2);
	MADStoreGraph *another = [MADStoreGraph new];
	[another addObject:second];
	MAD_PASS([store writeGraph:another error:&error], "the second write succeeds");

	NSArray<MADStoreObject *> *rows = [store objectsForEntity:@"RptqAlignment" error:&error];
	MAD_PASS(rows.count == (NSUInteger)2, "two alignment rows exist");
	MAD_PASS_EQUAL([rows.firstObject attributeValue:@"horizontal"], @1, "the first row is the identifier 7 row");
	MAD_PASS_EQUAL([rows.lastObject attributeValue:@"horizontal"], @2, "the second row is the surrogate row");
	MAD_PASS(rows.lastObject.identifier > (int64_t)7, "the surrogate is allocated past the rows already there");

	closeAndRemove(store, directory);
}

/// The model's own `identifier` attribute is the row key, so a graph that also
/// carries it as a value is contradictory and is refused rather than written twice.
static void testWritingAnIdentifierValueIsRefused(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"identifier", @1);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:document];

	NSError *error = nil;
	MAD_PASS(![store writeGraph:graph error:&error], "writing the identifier as a value is refused");
	MAD_PASS(error.code == MADStoreErrorUnwritableAttribute, "the error names the unwritable attribute");

	closeAndRemove(store, directory);
}

static void testWritingAnUnknownAttributeIsRefused(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"nonesuch", @1);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:document];

	NSError *error = nil;
	MAD_PASS(![store writeGraph:graph error:&error], "writing an unknown attribute is refused");
	MAD_PASS(error.code == MADStoreErrorUnknownAttribute, "the error names the unknown attribute");

	closeAndRemove(store, directory);
}

static void testReplacingAllClearsWhatWasThereBefore(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "the fixture writes");

	MADStoreGraph *smaller = [MADStoreGraph new];
	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"papersize", @4);
	[smaller addObject:document];
	MAD_PASS([store writeGraph:smaller replacingAll:YES error:&error], "the smaller graph writes");

	MADStoreGraph *read = [store allObjectsWithError:&error];
	MAD_PASS(read.count == (NSUInteger)1, "only the smaller graph is left");
	MAD_PASS([read objectForEntity:@"RptqDatabaseSchemaField" identifier:12] == nil, "the replaced rows are gone");

	closeAndRemove(store, directory);
}

static void testWritingWithoutReplacingLeavesTheRestAlone(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "the fixture writes");

	MADStoreObject *document = Object(@"RptqDocument", 2);
	SetValue(document, @"papersize", @5);
	MAD_PASS([store writeObject:document error:&error], "the single object writes");

	MAD_PASS([store objectForEntity:@"RptqDocument" identifier:1 error:&error] != nil, "the original document is still there");
	MAD_PASS([store objectForEntity:@"RptqDocument" identifier:2 error:&error] != nil, "the new document is there");

	closeAndRemove(store, directory);
}

static void testDeleteObject(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	NSError *error = nil;
	MAD_PASS([store writeGraph:fixtureGraph() replacingAll:YES error:&error], "the fixture writes");
	MAD_PASS([store deleteObjectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error], "the label row deletes");
	MAD_PASS([store objectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error] == nil, "the deleted row is gone");
	MAD_PASS([store objectForEntity:@"RptqDocumentElementImage" identifier:51 error:&error] != nil, "the sibling row is untouched");

	closeAndRemove(store, directory);
}

static void testClosedStoreRefusesToRead(void) {
	NSURL *directory = makeTempDirectory();
	MADStore *store = makeOpenStore([directory URLByAppendingPathComponent:@"definition.sqlite"]);

	MADStore *closed = [MADStore storeWithURL:store.url];
	NSError *error = nil;
	MAD_PASS(![closed isOpen], "a fresh store is not open");
	MAD_PASS([closed objectForEntity:@"RptqDocument" identifier:1 error:&error] == nil, "a closed store reads nothing");
	MAD_PASS(error.code == MADStoreErrorNotOpen, "the error says the store is not open");

	closeAndRemove(store, directory);
}

#pragma mark - Fidelity against the compiled model

// The original cross-checked every descriptor against Core Data's compiled MAD.momd
// -- the model bundle's NSManagedObjectModel, its entity and relationship
// descriptions, and the deliberate rename/expansion/transform exceptions.  Core
// Data does not exist off Apple and the model bundle is not compiled here, so the
// check reports a need; docs/project/MAD_LINUX.md §4 and docs/project/MAD_STORE_MIGRATION.md record why the
// model left the framework.
static void testSchemaMatchesEveryModelEntity(void) {
	MAD_NEED(NO, @"the model fidelity check needs Core Data and the compiled MAD.momd, which are Apple-only");
}

MAD_TEST_MAIN("MADStoreTests",
	MAD_TEST(testSchemaCoversEveryEntityOnce),
	MAD_TEST(testSubentitiesShareTheElementTable),
	MAD_TEST(testPositionColumnsLandOnTheChildTable),
	MAD_TEST(testSchemaSQLCreatesEveryTableOnce),
	MAD_TEST(testRoundTripOfAWholeDefinition),
	MAD_TEST(testRoundTripIsStableAcrossASecondWrite),
	MAD_TEST(testFetchByIdentifier),
	MAD_TEST(testFetchUnknownEntityAndMissingRow),
	MAD_TEST(testFetchByPart),
	MAD_TEST(testOrderedRelationshipsKeepTheirOrder),
	MAD_TEST(testManyToManySurvivesTheJoinTable),
	MAD_TEST(testDerivedToOneEdgesComeBackFromTheOwningSide),
	MAD_TEST(testAttributeValueTypesSurvive),
	MAD_TEST(testSatelliteWithoutAModelIdentifierGetsASurrogate),
	MAD_TEST(testSurrogateIsAllocatedPastTheRowsAlreadyThere),
	MAD_TEST(testWritingAnIdentifierValueIsRefused),
	MAD_TEST(testWritingAnUnknownAttributeIsRefused),
	MAD_TEST(testReplacingAllClearsWhatWasThereBefore),
	MAD_TEST(testWritingWithoutReplacingLeavesTheRestAlone),
	MAD_TEST(testDeleteObject),
	MAD_TEST(testClosedStoreRefusesToRead),
	MAD_TEST(testSchemaMatchesEveryModelEntity));
