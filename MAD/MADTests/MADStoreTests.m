//
//  MADStoreTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the portable store: the schema descriptors, and a headless round
//  trip of a document definition through a real SQLite file.  Nothing here touches
//  Core Data except the fidelity test, which cross-checks the descriptors against
//  the compiled model so the transcription cannot drift.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

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

@interface MADStoreTests : XCTestCase
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) MADStore *store;
@end

@implementation MADStoreTests

#pragma mark - Lifecycle

- (void)setUp {
	[super setUp];
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"definition.sqlite"]];
	self.store = [MADStore storeWithURL:self.url];
	NSError *error = nil;
	XCTAssertTrue([self.store openWithError:&error], @"open failed: %@", error);
}

- (void)tearDown {
	[self.store close];
	[[NSFileManager defaultManager] removeItemAtURL:self.url.URLByDeletingLastPathComponent error:NULL];
	self.store = nil;
	[super tearDown];
}

#pragma mark - The fixture

/// A document with a detail section and a report header, elements with their value
/// satellites, a database with a table of three fields, and a query that selects
/// two of those fields in an order of its own.  Between them the fixture covers
/// every column type, all four ordered relationships, the one many-to-many, and
/// both shared-table and satellite rows.
- (MADStoreGraph *)fixtureGraph {
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

- (MADStoreGraph *)writeAndReadFixture {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error], @"write failed: %@", error);
	MADStoreGraph *read = [self.store allObjectsWithError:&error];
	XCTAssertNotNil(read, @"read failed: %@", error);
	return read;
}

- (void)assertGraph:(MADStoreGraph *)actual equalsGraph:(MADStoreGraph *)expected {
	XCTAssertEqual(actual.count, expected.count, @"object count");
	for (MADStoreObject *object in [expected allObjects]) {
		MADStoreObject *other = [actual objectForEntity:object.entity identifier:object.identifier];
		if (!other) {
			XCTFail(@"missing %@ %lld", object.entity, (long long)object.identifier);
			continue;
		}
		if (![object isEqualToObject:other]) {
			XCTFail(@"%@ %lld\n expected %@\n actual   %@",
					object.entity, (long long)object.identifier, object, other);
		}
	}
}

#pragma mark - Schema

- (void)testSchemaCoversEveryEntityOnce {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	XCTAssertEqual(schema.entities.count, (NSUInteger)33);
	XCTAssertEqual(schema.tables.count, (NSUInteger)24);

	NSMutableSet<NSString *> *names = [NSMutableSet set];
	for (MADStoreEntity *entity in schema.entities) {
		XCTAssertFalse([names containsObject:entity.name], @"duplicate %@", entity.name);
		[names addObject:entity.name];
		XCTAssertNotNil(entity.table);
	}
	XCTAssertEqual(names.count, (NSUInteger)33);
}

- (void)testSubentitiesShareTheElementTable {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MADStoreEntity *element = [schema entityNamed:@"RptqDocumentElement"];
	XCTAssertNotNil(element);
	XCTAssertEqual(element.subentities.count, (NSUInteger)9);
	XCTAssertFalse(element.isSubentity);

	for (MADStoreEntity *subentity in element.subentities) {
		XCTAssertTrue(subentity.isSubentity);
		XCTAssertEqualObjects(subentity.table, @"RptqDocumentElement");
		// The base's attributes and edges are inherited, not repeated.
		XCTAssertEqual(subentity.allAttributes.count,
					   element.attributes.count + subentity.attributes.count);
		XCTAssertNotNil([subentity anyRelationshipNamed:@"inSectionRow"]);
	}
}

/// The `position` column sits on the child table, next to the foreign key that
/// points back at the parent -- one column per child, not one per relationship.
- (void)testPositionColumnsLandOnTheChildTable {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSMutableSet<NSString *> *positioned = [NSMutableSet set];
	for (MADStoreEntity *table in schema.tables) {
		if (table.hasPositionColumn) [positioned addObject:table.name];
	}
	NSSet *expected = [NSSet setWithObjects:@"RptqDatabaseSchemaField", @"RptqQueryTable",
					   @"RptqDocumentSectionRows", @"RptqDocumentElement", nil];
	XCTAssertEqualObjects(positioned, expected);
}

- (void)testSchemaSQLCreatesEveryTableOnce {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSString *sql = schema.createSchemaSQL;
	for (MADStoreEntity *table in schema.tables) {
		NSString *statement = [[NSString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS \"%@\"", table.name];
		NSRange range = [sql rangeOfString:statement];
		XCTAssertNotEqual(range.location, (NSUInteger)NSNotFound, @"no table for %@", table.name);
		NSRange rest = NSMakeRange(range.location + 1, sql.length - range.location - 1);
		XCTAssertEqual([sql rangeOfString:statement options:0 range:rest].location,
					   (NSUInteger)NSNotFound, @"%@ created twice", table.name);
	}
	XCTAssertNotEqual([sql rangeOfString:@"\"RptqQueryHasFields\""].location, (NSUInteger)NSNotFound);
}

#pragma mark - Round trip

- (void)testRoundTripOfAWholeDefinition {
	MADStoreGraph *expected = [[self fixtureGraph] graphByCompletingInverses];
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error], @"write failed: %@", error);

	MADStoreGraph *actual = [self.store allObjectsWithError:&error];
	XCTAssertNotNil(actual, @"read failed: %@", error);
	[self assertGraph:actual equalsGraph:expected];
}

- (void)testRoundTripIsStableAcrossASecondWrite {
	MADStoreGraph *first = [self writeAndReadFixture];

	// Writing back what was read is what a save after an edit looks like.  It must
	// not duplicate a row or drop an edge.
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:first replacingAll:YES error:&error], @"rewrite failed: %@", error);
	MADStoreGraph *second = [self.store allObjectsWithError:&error];
	XCTAssertNotNil(second, @"reread failed: %@", error);
	[self assertGraph:second equalsGraph:first];
}

- (void)testFetchByIdentifier {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error]);

	MADStoreObject *table = [self.store objectForEntity:@"RptqDatabaseSchemaTable" identifier:11 error:&error];
	XCTAssertNotNil(table);
	XCTAssertEqualObjects([table attributeValue:@"name"], @"customers");
	XCTAssertEqualObjects([table referenceForName:@"inDatabase"], @10);
	// A flat read carries no edges beyond the ones this row owns.
	XCTAssertNil([table existingCollectionForName:@"hasFields"]);

	MADStoreObject *element = [self.store objectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error];
	XCTAssertNotNil(element, @"a subentity is addressed by its own name");
	XCTAssertEqualObjects([element attributeValue:@"text"], @"Hello, world");
	XCTAssertEqualObjects([element referenceForName:@"inSectionRow"], @40);

	// The same identifier under a sibling kind is a different row, and is not there.
	XCTAssertNil([self.store objectForEntity:@"RptqDocumentElementImage" identifier:50 error:&error]);
}

- (void)testFetchUnknownEntityAndMissingRow {
	NSError *error = nil;
	XCTAssertNil([self.store objectForEntity:@"RptqNonesuch" identifier:1 error:&error]);
	XCTAssertEqual(error.code, MADStoreErrorUnknownEntity);

	error = nil;
	XCTAssertNil([self.store objectForEntity:@"RptqDocument" identifier:999 error:&error]);
	XCTAssertNil(error, @"an absent row is not an error");
}

- (void)testFetchByPart {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error]);

	// The database, its table, and the table's three fields.
	MADStoreGraph *schema = [self.store graphForPart:MADStorePartSchema error:&error];
	XCTAssertNotNil(schema);
	XCTAssertEqual(schema.count, (NSUInteger)5);
	XCTAssertNotNil([schema objectForEntity:@"RptqDatabaseSchemaTable" identifier:11]);
	XCTAssertNil([schema objectForEntity:@"RptqDocument" identifier:1]);

	// The query, its table reference, and its field reference.
	MADStoreGraph *query = [self.store graphForPart:MADStorePartQuery error:&error];
	XCTAssertEqual(query.count, (NSUInteger)3);
	XCTAssertNotNil([query objectForEntity:@"RptqQuery" identifier:20]);

	// Everything the designer draws.
	MADStoreGraph *layout = [self.store graphForPart:MADStorePartLayout error:&error];
	XCTAssertNotNil([layout objectForEntity:@"RptqDocument" identifier:1]);
	XCTAssertNotNil([layout objectForEntity:@"RptqDocumentElementLabel" identifier:50]);
	XCTAssertNil([layout objectForEntity:@"RptqDatabase" identifier:10]);
}

- (void)testOrderedRelationshipsKeepTheirOrder {
	MADStoreGraph *graph = [self writeAndReadFixture];

	MADStoreObject *table = [graph objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	XCTAssertEqualObjects([table existingCollectionForName:@"hasFields"], (@[ @13, @14, @12 ]));

	MADStoreObject *detail = [graph objectForEntity:@"RptqDocumentSection" identifier:30];
	XCTAssertEqualObjects([detail existingCollectionForName:@"hasRows"], (@[ @41, @40 ]));

	MADStoreObject *secondRow = [graph objectForEntity:@"RptqDocumentSectionRows" identifier:41];
	XCTAssertEqualObjects([secondRow existingCollectionForName:@"hasObjects"], (@[ @51 ]));

	MADStoreObject *firstRow = [graph objectForEntity:@"RptqDocumentSectionRows" identifier:40];
	XCTAssertEqualObjects([firstRow existingCollectionForName:@"hasObjects"], (@[ @50 ]));

	// A section with no rows has an empty edge, not a missing one.
	MADStoreObject *header = [graph objectForEntity:@"RptqDocumentSection" identifier:31];
	XCTAssertEqual([header existingCollectionForName:@"hasRows"].count, (NSUInteger)0);
}

- (void)testManyToManySurvivesTheJoinTable {
	MADStoreGraph *graph = [self writeAndReadFixture];

	MADStoreObject *query = [graph objectForEntity:@"RptqQuery" identifier:20];
	XCTAssertEqualObjects([query existingCollectionForName:@"hasFields"], (@[ @12, @13 ]));

	for (NSNumber *identifier in @[ @12, @13 ]) {
		MADStoreObject *field = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:identifier.longLongValue];
		XCTAssertEqualObjects([field existingCollectionForName:@"inQuery"], (@[ @20 ]));
	}

	// The field the query does not select is in no join row.
	MADStoreObject *emailField = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:14];
	XCTAssertEqual([emailField existingCollectionForName:@"inQuery"].count, (NSUInteger)0);
}

- (void)testDerivedToOneEdgesComeBackFromTheOwningSide {
	MADStoreGraph *graph = [self writeAndReadFixture];

	// RptqDocument owns no foreign key; its sections are found through theirs.
	MADStoreObject *document = [graph objectForEntity:@"RptqDocument" identifier:1];
	XCTAssertEqualObjects([document referenceForName:@"hasDetailSection"], @30);
	XCTAssertEqualObjects([document referenceForName:@"hasReportHeaderSection"], @31);
	XCTAssertNil([document referenceForName:@"hasPageHeaderSection"]);

	MADStoreObject *label = [graph objectForEntity:@"RptqDocumentElementLabel" identifier:50];
	XCTAssertEqualObjects([label referenceForName:@"rect"], @60);
	XCTAssertEqualObjects([label referenceForName:@"alignment"], @63);
	XCTAssertEqualObjects([label referenceForName:@"numericFormat"], @64);
	XCTAssertEqualObjects([label referenceForName:@"padding"], @65);

	// And the far side of each pair is filled in too.
	MADStoreObject *rect = [graph objectForEntity:@"RptqRect" identifier:60];
	XCTAssertEqualObjects([rect referenceForName:@"inElement"], @50);
	XCTAssertEqualObjects([rect referenceForName:@"origin"], @61);
	XCTAssertEqualObjects([rect referenceForName:@"size"], @62);
}

- (void)testAttributeValueTypesSurvive {
	MADStoreGraph *graph = [self writeAndReadFixture];

	MADStoreObject *label = [graph objectForEntity:@"RptqDocumentElementLabel" identifier:50];
	XCTAssertEqualObjects([label attributeValue:@"fontsize"], @12.5);
	XCTAssertEqualObjects([label attributeValue:@"backgroundColorG"], @0.5);

	MADStoreObject *image = [graph objectForEntity:@"RptqDocumentElementImage" identifier:51];
	XCTAssertEqualObjects([image attributeValue:@"image"], [@"PNG-ish bytes" dataUsingEncoding:NSUTF8StringEncoding]);

	MADStoreObject *format = [graph objectForEntity:@"RptqNumericFormat" identifier:64];
	XCTAssertEqualObjects([format attributeValue:@"locale"], @"en_US");

	// An attribute left unset comes back absent, not as a null.
	MADStoreObject *nameField = [graph objectForEntity:@"RptqDatabaseSchemaField" identifier:13];
	XCTAssertNil([nameField attributeValue:@"decimals"]);
	XCTAssertNil([nameField attributeValue:@"primaryKey"]);
	XCTAssertEqual(nameField.values.count, (NSUInteger)2);
}

#pragma mark - Writing

- (void)testSatelliteWithoutAModelIdentifierGetsASurrogate {
	MADStoreObject *alignment = Object(@"RptqAlignment", 0);
	SetValue(alignment, @"horizontal", @1);
	SetValue(alignment, @"vertical", @3);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:alignment];

	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:graph error:&error], @"write failed: %@", error);

	NSArray<MADStoreObject *> *rows = [self.store objectsForEntity:@"RptqAlignment" error:&error];
	XCTAssertEqual(rows.count, (NSUInteger)1);
	XCTAssertGreaterThan(rows.firstObject.identifier, (int64_t)0);
	XCTAssertEqualObjects([rows.firstObject attributeValue:@"vertical"], @3);
}

/// A surrogate is allocated past whatever the table already holds, so a second
/// write cannot land on a row that is already there.
- (void)testSurrogateIsAllocatedPastTheRowsAlreadyThere {
	MADStoreObject *first = Object(@"RptqAlignment", 7);
	SetValue(first, @"horizontal", @1);
	SetValue(first, @"vertical", @1);
	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:first];
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:graph error:&error]);

	MADStoreObject *second = Object(@"RptqAlignment", 0);
	SetValue(second, @"horizontal", @2);
	SetValue(second, @"vertical", @2);
	MADStoreGraph *another = [MADStoreGraph new];
	[another addObject:second];
	XCTAssertTrue([self.store writeGraph:another error:&error]);

	NSArray<MADStoreObject *> *rows = [self.store objectsForEntity:@"RptqAlignment" error:&error];
	XCTAssertEqual(rows.count, (NSUInteger)2);
	XCTAssertEqualObjects([rows.firstObject attributeValue:@"horizontal"], @1);
	XCTAssertEqualObjects([rows.lastObject attributeValue:@"horizontal"], @2);
	XCTAssertGreaterThan(rows.lastObject.identifier, (int64_t)7);
}

/// The model's own `identifier` attribute is the row key, so a graph that also
/// carries it as a value is contradictory and is refused rather than written twice.
- (void)testWritingAnIdentifierValueIsRefused {
	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"identifier", @1);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:document];

	NSError *error = nil;
	XCTAssertFalse([self.store writeGraph:graph error:&error]);
	XCTAssertEqual(error.code, MADStoreErrorUnwritableAttribute);
}

- (void)testWritingAnUnknownAttributeIsRefused {
	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"nonesuch", @1);

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:document];

	NSError *error = nil;
	XCTAssertFalse([self.store writeGraph:graph error:&error]);
	XCTAssertEqual(error.code, MADStoreErrorUnknownAttribute);
}

- (void)testReplacingAllClearsWhatWasThereBefore {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error]);

	MADStoreGraph *smaller = [MADStoreGraph new];
	MADStoreObject *document = Object(@"RptqDocument", 1);
	SetValue(document, @"papersize", @4);
	[smaller addObject:document];
	XCTAssertTrue([self.store writeGraph:smaller replacingAll:YES error:&error]);

	MADStoreGraph *read = [self.store allObjectsWithError:&error];
	XCTAssertEqual(read.count, (NSUInteger)1);
	XCTAssertNil([read objectForEntity:@"RptqDatabaseSchemaField" identifier:12]);
}

- (void)testWritingWithoutReplacingLeavesTheRestAlone {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error]);

	MADStoreObject *document = Object(@"RptqDocument", 2);
	SetValue(document, @"papersize", @5);
	XCTAssertTrue([self.store writeObject:document error:&error]);

	XCTAssertNotNil([self.store objectForEntity:@"RptqDocument" identifier:1 error:&error]);
	XCTAssertNotNil([self.store objectForEntity:@"RptqDocument" identifier:2 error:&error]);
}

- (void)testDeleteObject {
	NSError *error = nil;
	XCTAssertTrue([self.store writeGraph:[self fixtureGraph] replacingAll:YES error:&error]);
	XCTAssertTrue([self.store deleteObjectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error]);
	XCTAssertNil([self.store objectForEntity:@"RptqDocumentElementLabel" identifier:50 error:&error]);
	XCTAssertNotNil([self.store objectForEntity:@"RptqDocumentElementImage" identifier:51 error:&error]);
}

- (void)testClosedStoreRefusesToRead {
	MADStore *closed = [MADStore storeWithURL:self.url];
	NSError *error = nil;
	XCTAssertFalse([closed isOpen]);
	XCTAssertNil([closed objectForEntity:@"RptqDocument" identifier:1 error:&error]);
	XCTAssertEqual(error.code, MADStoreErrorNotOpen);
}

#pragma mark - Fidelity against the compiled model

- (NSManagedObjectModel *)modelFromTestBundle {
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD" withExtension:@"momd"];
	XCTAssertNotNil(momdURL, @"MAD.momd was not compiled into the test bundle.");
	return [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
}

/// The two places the store deliberately parts company with the model, both
/// recorded here so an accidental third one shows up as a failure.
static NSDictionary *MADStoreAttributeRenames(void) {
	return @{ @"dbkey": @"key" };
}

static NSDictionary *MADStoreAttributeExpansions(void) {
	return @{
		@"backgroundColor": @[ @"backgroundColorR", @"backgroundColorG", @"backgroundColorB", @"backgroundColorA" ],
		@"foregroundColor": @[ @"foregroundColorR", @"foregroundColorG", @"foregroundColorB", @"foregroundColorA" ],
	};
}

/// A transformable that keeps its name but changes its column type.  The colour
/// transformables are in the expansion map instead, because they become four
/// columns each.
static NSDictionary *MADStoreTransformedAttributes(void) {
	return @{ @"image": @(MADStoreValueTypeBlob), @"locale": @(MADStoreValueTypeText) };
}

static MADStoreValueType MADStoreExpectedType(NSAttributeType type) {
	switch (type) {
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
		case NSBooleanAttributeType:
			return MADStoreValueTypeInteger;
		case NSFloatAttributeType:
		case NSDoubleAttributeType:
		case NSDecimalAttributeType:
			return MADStoreValueTypeReal;
		case NSStringAttributeType:
			return MADStoreValueTypeText;
		default:
			return MADStoreValueTypeBlob;
	}
}

- (void)testSchemaMatchesEveryModelEntity {
	NSManagedObjectModel *model = [self modelFromTestBundle];
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	XCTAssertEqual(model.entities.count, schema.entities.count);

	for (NSEntityDescription *entity in model.entities) {
		MADStoreEntity *descriptor = [schema entityNamed:entity.name];
		if (!descriptor) { XCTFail(@"no descriptor for %@", entity.name); continue; }

		XCTAssertEqualObjects(descriptor.parentName, entity.superentity.name, @"%@ superentity", entity.name);
		XCTAssertEqual(descriptor.subentities.count, entity.subentities.count, @"%@ subentities", entity.name);

		// Attributes: every model attribute is expected, under its name or its
		// rename or its expansion, and nothing else is.  Core Data hands a subentity
		// its inherited properties, so the comparison is against the entity's whole
		// set on both sides -- -allAttributes walks the same chain.
		NSDictionary *renames = MADStoreAttributeRenames();
		NSDictionary *expansions = MADStoreAttributeExpansions();
		NSMutableSet<NSString *> *expectedAttributes = [NSMutableSet set];
		NSMutableDictionary<NSString *, NSNumber *> *expectedTypes = [NSMutableDictionary dictionary];
		NSMutableDictionary<NSString *, NSAttributeDescription *> *source = [NSMutableDictionary dictionary];
		for (NSAttributeDescription *attribute in entity.attributesByName.allValues) {
			NSArray<NSString *> *expansion = expansions[attribute.name];
			if (expansion) {
				XCTAssertEqual(attribute.attributeType, NSTransformableAttributeType, @"%@", attribute.name);
				for (NSString *name in expansion) {
					[expectedAttributes addObject:name];
					expectedTypes[name] = @(MADStoreValueTypeReal);
					source[name] = attribute;
				}
				continue;
			}
			NSString *name = renames[attribute.name] ?: attribute.name;
			NSNumber *transformed = MADStoreTransformedAttributes()[attribute.name];
			if (transformed) {
				XCTAssertEqual(attribute.attributeType, NSTransformableAttributeType, @"%@", attribute.name);
				expectedTypes[name] = transformed;
			} else {
				XCTAssertNotEqual(attribute.attributeType, NSTransformableAttributeType, @"%@", attribute.name);
				expectedTypes[name] = @(MADStoreExpectedType(attribute.attributeType));
			}
			[expectedAttributes addObject:name];
			source[name] = attribute;
		}

		NSMutableSet<NSString *> *actualAttributes = [NSMutableSet set];
		for (MADStoreAttribute *attribute in descriptor.allAttributes) {
			[actualAttributes addObject:attribute.name];
			NSNumber *expected = expectedTypes[attribute.name];
			if (!expected) { XCTFail(@"%@ has a surplus attribute %@", entity.name, attribute.name); continue; }
			XCTAssertEqual(attribute.type, (MADStoreValueType)expected.integerValue,
						   @"%@.%@ type", entity.name, attribute.name);
			XCTAssertEqual(attribute.isOptional, source[attribute.name].isOptional,
						   @"%@.%@ optionality", entity.name, attribute.name);
		}
		for (NSString *name in expectedAttributes) {
			XCTAssertTrue([actualAttributes containsObject:name], @"%@ is missing attribute %@", entity.name, name);
		}

		// Relationships: name, destination, cardinality, ordering and inverse, all
		// of them the entity declares itself.  Inherited ones are checked on the
		// entity that declares them.
		NSMutableSet<NSString *> *expectedRelationships = [NSMutableSet set];
		for (NSRelationshipDescription *relationship in entity.relationshipsByName.allValues) {
			[expectedRelationships addObject:relationship.name];

			MADStoreRelationship *descriptor2 = [descriptor anyRelationshipNamed:relationship.name];
			if (!descriptor2) { XCTFail(@"%@ is missing relationship %@", entity.name, relationship.name); continue; }
			XCTAssertEqualObjects(descriptor2.destination, relationship.destinationEntity.name,
								  @"%@.%@ destination", entity.name, relationship.name);
			XCTAssertEqual(descriptor2.isToMany, relationship.isToMany, @"%@.%@ to-many", entity.name, relationship.name);
			XCTAssertEqual(descriptor2.isOrdered, relationship.isOrdered, @"%@.%@ ordered", entity.name, relationship.name);
			XCTAssertEqualObjects(descriptor2.inverse, relationship.inverseRelationship.name,
								  @"%@.%@ inverse", entity.name, relationship.name);
		}
		for (MADStoreRelationship *relationship in descriptor.allRelationships) {
			XCTAssertTrue([expectedRelationships containsObject:relationship.name],
						  @"%@ has a surplus relationship %@", entity.name, relationship.name);
		}
	}
}

@end
