//
//  RptqStoreContextTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the Phase C mechanism: the plain store-backed RptqObject and the
//  RptqStoreContext that replaces the NSManagedObjectContext role.  The schema family
//  is the proof -- it round-trips through the context exactly the way
//  MADOperationCreateDocumentImportSchema builds it, and it reads back out of a real
//  converted sample.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/RptqObject.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/MADStore.h>
#import "MADStoreConverter.h"

/// A stand-in for a swapped Rptq entity: the same @dynamic shape the real classes keep,
/// over a RptqDatabase row, so the dynamic accessors are exercised end to end.
@interface RptqDynamicAccessStub : RptqObject
@property (nonatomic, copy) NSString *databaseDriverType;
@property (nonatomic) int16_t databaseDriverTypeEnum;
@end
@implementation RptqDynamicAccessStub
@dynamic databaseDriverType;
@dynamic databaseDriverTypeEnum;
@end

@interface RptqStoreContextTests : XCTestCase
@property (nonatomic, strong) NSURL *directory;
@end

@implementation RptqStoreContextTests

- (void)setUp {
	[super setUp];
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.directory = [NSURL fileURLWithPath:directory isDirectory:YES];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	[super tearDown];
}

- (RptqStoreContext *)openContextAtPath:(NSString *)name {
	NSURL *url = [self.directory URLByAppendingPathComponent:name];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	return [RptqStoreContext contextWithStore:store];
}

#pragma mark - The schema family, round-tripped

/// Builds the same schema the import flow does -- a document, one database, its
/// credentials, and tables with ordered fields -- through the context, saves, reopens
/// from disk, and asserts every attribute and edge survived in both directions.
- (void)testSchemaRoundTripsThroughTheContext {
	RptqStoreContext *context = [self openContextAtPath:@"schema.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqObject *credential = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];

	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[database setValue:@2 forKey:@"databaseDriverTypeEnum"];
	[credential setValue:@"chinook.sqlite3" forKey:@"dbname"];
	[credential setValue:@"Sqlite 3" forKey:@"driverID"];

	RptqObject *customers = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[customers setValue:@"customers" forKey:@"name"];
	[customers setValue:@YES forKey:@"queryable"];

	RptqObject *invoices = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	[invoices setValue:@"invoices" forKey:@"name"];

	RptqObject *idField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[idField setValue:@"id" forKey:@"name"];
	RptqObject *nameField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[nameField setValue:@"name" forKey:@"name"];
	RptqObject *emailField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:22];
	[emailField setValue:@"email" forKey:@"name"];

	// Wire the edges the import flow wires, setting the owning sides and letting the
	// context maintain the inverses.
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
	[database setValue:credential forKey:@"ownedByUser"];
	[database setValue:@[ customers, invoices ] forKey:@"hasTables"];
	[customers setValue:@[ idField, nameField, emailField ] forKey:@"hasFields"];

	NSError *error = nil;
	XCTAssertTrue([context save:&error], @"save failed: %@", error);

	// A fresh context over the same file is a real read-from-disk, not the in-memory
	// registry.
	RptqStoreContext *reread = [self openContextAtPath:@"schema.sqlite"];
	XCTAssertTrue([reread loadAllWithError:&error], @"load failed: %@", error);

	RptqObject *readDocument = [reread objectForEntity:@"RptqDocument" identifier:1];
	XCTAssertNotNil(readDocument);
	NSSet *databases = [readDocument valueForKey:@"hasDatabaseSchemas"];
	XCTAssertEqual(databases.count, (NSUInteger)1);

	RptqObject *readDatabase = databases.anyObject;
	XCTAssertEqual(readDatabase.identifier, (int64_t)10);
	XCTAssertEqualObjects([readDatabase valueForKey:@"databaseDriverType"], @"Sqlite 3");
	XCTAssertEqualObjects([readDatabase valueForKey:@"databaseDriverTypeEnum"], @2);

	// The credential came back minted a non-zero identifier, and both directions of
	// the one-to-one hold.
	RptqObject *readCredential = [readDatabase valueForKey:@"ownedByUser"];
	XCTAssertNotNil(readCredential);
	XCTAssertGreaterThan(readCredential.identifier, (int64_t)0);
	RptqObject *credentialDatabase = [readCredential valueForKey:@"inDatabase"];
	XCTAssertEqual(credentialDatabase.identifier, readDatabase.identifier);
	XCTAssertEqualObjects([readCredential valueForKey:@"dbname"], @"chinook.sqlite3");

	NSSet *tables = [readDatabase valueForKey:@"hasTables"];
	XCTAssertEqual(tables.count, (NSUInteger)2);

	RptqObject *readCustomers = nil;
	for (RptqObject *table in tables) {
		RptqObject *owningDatabase = [table valueForKey:@"inDatabase"];
		XCTAssertEqual(owningDatabase.identifier, readDatabase.identifier);
		if ([[table valueForKey:@"name"] isEqualToString:@"customers"]) readCustomers = table;
	}
	XCTAssertNotNil(readCustomers);
	XCTAssertEqualObjects([readCustomers valueForKey:@"queryable"], @YES);

	NSOrderedSet *fields = [readCustomers valueForKey:@"hasFields"];
	XCTAssertEqual(fields.count, (NSUInteger)3);
	XCTAssertEqualObjects([fields[0] valueForKey:@"name"], @"id");
	XCTAssertEqualObjects([fields[1] valueForKey:@"name"], @"name");
	XCTAssertEqualObjects([fields[2] valueForKey:@"name"], @"email");
	for (RptqObject *field in fields) {
		RptqObject *owningTable = [field valueForKey:@"inTable"];
		XCTAssertEqual(owningTable.identifier, readCustomers.identifier);
	}
}

/// A context returns the same object for the same (entity, identifier), so identity
/// holds across faults -- what the app expects of an object graph.
- (void)testFaultingReturnsStableIdentities {
	RptqStoreContext *context = [self openContextAtPath:@"identity.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	[context insertObjectForEntity:@"RptqDatabase" identifier:10];
	XCTAssertTrue([context save:NULL]);

	RptqStoreContext *reread = [self openContextAtPath:@"identity.sqlite"];
	XCTAssertTrue([reread loadAllWithError:NULL]);

	RptqObject *first = [reread objectForEntity:@"RptqDatabase" identifier:10];
	RptqObject *second = [reread objectForEntity:@"RptqDatabase" identifier:10];
	XCTAssertEqual(first, second);
}

/// The swapped classes keep @dynamic dot-syntax working: +resolveInstanceMethod: on the
/// base installs typed getters and setters that read and write the backing row.
- (void)testDynamicAccessorsServeDotSyntax {
	RptqStoreContext *context = [self openContextAtPath:@"dynamic.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	MADStoreObject *backing = [MADStoreObject objectWithEntity:@"RptqDatabase" identifier:10];
	RptqDynamicAccessStub *stub = [RptqDynamicAccessStub objectWithBackingObject:backing storeContext:context];

	stub.databaseDriverType = @"Sqlite 3";
	stub.databaseDriverTypeEnum = 2;

	XCTAssertEqualObjects(stub.databaseDriverType, @"Sqlite 3");
	XCTAssertEqual(stub.databaseDriverTypeEnum, (int16_t)2);
	XCTAssertEqual(stub.identifier, (int64_t)10);
}

#pragma mark - A real document

/// Reads the schema family back out of a converted shipping sample through the
/// mechanism, so the census and the edges are pinned to a real document rather than a
/// hand-built one.
- (void)testSchemaFamilyReadsBackFromAConvertedSample {
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
	NSURL *sampleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"London" withExtension:@"mad"];
	NSURL *storeURL = [self.directory URLByAppendingPathComponent:@"london.sqlite"];

	NSError *error = nil;
	XCTAssertNotNil([MADStoreConverter convertDocumentAtURL:sampleURL
											   toStoreAtURL:storeURL
													  model:model
													  error:&error],
					@"conversion failed: %@", error);

	RptqStoreContext *context = [self openContextAtPath:@"london.sqlite"];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);

	XCTAssertEqual([context objectsForEntity:@"RptqDatabase"].count, (NSUInteger)1);
	XCTAssertEqual([context objectsForEntity:@"RptqDatabaseSchemaTable"].count, (NSUInteger)11);
	XCTAssertEqual([context objectsForEntity:@"RptqDatabaseSchemaField"].count, (NSUInteger)64);

	RptqObject *database = [context objectsForEntity:@"RptqDatabase"].firstObject;
	NSSet *tables = [database valueForKey:@"hasTables"];
	XCTAssertEqual(tables.count, (NSUInteger)11);

	NSUInteger fields = 0;
	for (RptqObject *table in tables) {
		RptqObject *owningDatabase = [table valueForKey:@"inDatabase"];
		XCTAssertEqual(owningDatabase.identifier, database.identifier);
		fields += [[table valueForKey:@"hasFields"] count];
	}
	XCTAssertEqual(fields, (NSUInteger)64);
}

#pragma mark - The document path

/// The characterization pin for the MADDocument open/save rewire: a legacy Core Data
/// document is converted to the portable store on open, the store is written out again,
/// and reopening it hands back the same graph.
- (void)testDocumentPathConvertsSavesAndReopensUnchanged {
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
	NSURL *sampleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"London" withExtension:@"mad"];
	NSURL *firstURL = [self.directory URLByAppendingPathComponent:@"document.sqlite"];

	NSError *error = nil;
	// Convert-on-open: the legacy store becomes the portable one.
	MADStoreGraph *original = [MADStoreConverter convertDocumentAtURL:sampleURL
														  toStoreAtURL:firstURL
																 model:model
																 error:&error];
	XCTAssertNotNil(original, @"conversion failed: %@", error);

	// Save: write the loaded graph out to a fresh store, the way MADDocument writes on
	// save rather than round-tripping the converter's in-memory graph.
	MADStore *first = [MADStore storeWithURL:firstURL];
	XCTAssertTrue([first openWithError:&error], @"open failed: %@", error);
	MADStoreGraph *loaded = [first allObjectsWithError:&error];
	XCTAssertNotNil(loaded, @"read failed: %@", error);

	NSURL *secondURL = [self.directory URLByAppendingPathComponent:@"document-resaved.sqlite"];
	MADStore *second = [MADStore storeWithURL:secondURL];
	XCTAssertTrue([second openWithError:&error], @"open failed: %@", error);
	XCTAssertTrue([second writeGraph:loaded replacingAll:YES error:&error], @"write failed: %@", error);
	[second close];
	[first close];

	// Reopen and compare.
	MADStore *reopened = [MADStore storeWithURL:secondURL];
	XCTAssertTrue([reopened openWithError:&error], @"open failed: %@", error);
	MADStoreGraph *reread = [reopened allObjectsWithError:&error];
	XCTAssertNotNil(reread, @"read failed: %@", error);
	[reopened close];

	XCTAssertTrue([[reread graphByCompletingInverses] isEqualToGraph:[loaded graphByCompletingInverses]]);
}

#pragma mark - Change notification

// The context mirrors Core Data's change notification -- same name, object = the
// context, RptqStoreContextInsertedObjectsKey / RptqStoreContextUpdatedObjectsKey / RptqStoreContextDeletedObjectsKey --
// coalesced to one post per run-loop turn, so a gesture that sets many properties
// cannot storm the observers.
- (void)testChangeNotificationPostsCoalescedWithCoreDataKeys {
	RptqStoreContext *context = [self openContextAtPath:@"notify.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	XCTestExpectation *posted = [self expectationWithDescription:@"change notification"];
	__block NSUInteger postCount = 0;
	__block NSNotification *received = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:RptqStoreContextObjectsDidChangeNotification
																	object:context
																	 queue:[NSOperationQueue mainQueue]
																 usingBlock:^(NSNotification *note) {
		postCount++;
		received = note;
		[posted fulfill];
	}];

	// Many changes inside one turn: one notification for all of them.
	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:0];
	[table setValue:@"one" forKey:@"name"];
	[table setValue:@"two" forKey:@"name"];
	[table setValue:@"three" forKey:@"name"];
	RptqObject *second = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:0];
	[context deleteObject:second error:NULL];

	[self waitForExpectations:@[ posted ] timeout:5];

	NSSet *inserted = received.userInfo[RptqStoreContextInsertedObjectsKey];
	NSSet *updated = received.userInfo[RptqStoreContextUpdatedObjectsKey];
	NSSet *deleted = received.userInfo[RptqStoreContextDeletedObjectsKey];
	XCTAssertNotNil(inserted, @"the notification carries the Core Data userInfo keys");
	XCTAssertTrue([inserted containsObject:table], @"the inserted row is in RptqStoreContextInsertedObjectsKey");
	XCTAssertTrue([updated containsObject:table], @"the changed row is in RptqStoreContextUpdatedObjectsKey");
	XCTAssertTrue([deleted containsObject:second], @"the deleted row is in RptqStoreContextDeletedObjectsKey");
	XCTAssertFalse([inserted containsObject:second], @"a deleted insert leaves the inserted set");

	// A turn passes; the post count must still be one -- the burst coalesced.
	[NSThread sleepForTimeInterval:0.1];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	XCTAssertEqual(postCount, (NSUInteger)1, @"one run-loop turn, one notification");

	[[NSNotificationCenter defaultCenter] removeObserver:observer];
}

#pragma mark - Schema lookup memoization

// The flattened arrays and name indexes are warmed once at schema construction and
// never rebuilt; the render path depends on that -- a fresh array per call is what
// blew the large-report export up to gigabytes.
- (void)testSchemaFlattenedArraysAreMemoizedAndStable {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	for (MADStoreEntity *entity in schema.entities) {
		NSArray *attributes = entity.allAttributes;
		NSArray *relationships = entity.allRelationships;

		// Repeat calls return the same object -- the memoization, not just equal
		// content -- so the property layer allocates nothing per read.
		XCTAssertTrue(entity.allAttributes == attributes, @"%@ allAttributes reallocates", entity.name);
		XCTAssertTrue(entity.allRelationships == relationships, @"%@ allRelationships reallocates", entity.name);

		// The content is the ancestors' followed by the entity's own, and the name
		// indexes agree with the flattened arrays.
		if (entity.parentName != nil) {
			MADStoreEntity *parent = [schema entityNamed:entity.parentName];
			// A subentity may declare no attributes of its own (the chart kind), so
			// equality with the parent is legal; the tail check pins the rest.
			XCTAssertGreaterThanOrEqual(attributes.count, parent.allAttributes.count,
										@"%@ must flatten its ancestors' attributes", entity.name);
			NSArray *own = entity.attributes;
			XCTAssertEqualObjects([attributes subarrayWithRange:NSMakeRange(attributes.count - own.count, own.count)],
								  own, @"%@ ends with its own attributes", entity.name);
		} else {
			XCTAssertTrue(attributes == entity.attributes, @"a table owner's allAttributes is its own list");
		}
		for (MADStoreAttribute *attribute in attributes) {
			XCTAssertTrue([entity anyAttributeNamed:attribute.name] == attribute,
						  @"%@ %@ misses in the name index", entity.name, attribute.name);
		}
		for (MADStoreRelationship *relationship in relationships) {
			XCTAssertTrue([entity anyRelationshipNamed:relationship.name] == relationship,
						  @"%@ %@ misses in the name index", entity.name, relationship.name);
		}
	}
}

#pragma mark - RptqObject KVC semantics

// The property layer's behaviour must not change with the memoized lookups: reads,
// setter dirty-marking, unknown-key raising, and subclass-inherited attributes all
// behave exactly as before.
- (void)testRptqObjectKVCSemanticsAreUnchanged {
	RptqStoreContext *context = [self openContextAtPath:@"kvc.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:50];
	[table setValue:@"customers" forKey:@"name"];
	XCTAssertEqualObjects([table valueForKey:@"name"], @"customers", @"an attribute read");
	XCTAssertTrue([context save:NULL]);
	XCTAssertFalse(context.hasChanges);

	[table setValue:@"renamed" forKey:@"name"];
	XCTAssertEqualObjects([table valueForKey:@"name"], @"renamed");
	XCTAssertTrue(context.hasChanges, @"an attribute set marks the row dirty");

	// A set to the same value is not a change.
	[table setValue:@"renamed" forKey:@"name"];
	XCTAssertTrue(context.hasChanges);

	// An unknown key still raises through NSObject.
	XCTAssertThrows([table valueForKey:@"noSuchKeyAtAll"]);
	XCTAssertThrows([table setValue:@1 forKey:@"noSuchKeyAtAll"]);

	// A subentity reads the base element's attributes through the flattened index.
	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:60];
	[label setValue:@2 forKey:@"type"];
	XCTAssertEqualObjects([label valueForKey:@"type"], @2, @"a subclass reads an inherited attribute");

	// A to-many relationship read returns the member objects.
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:70];
	[database setValue:@[ table ] forKey:@"hasTables"];
	NSSet *tables = [database valueForKey:@"hasTables"];
	XCTAssertEqual(tables.count, (NSUInteger)1);
	XCTAssertTrue([tables containsObject:table], @"a to-many read faults the member");
}

#pragma mark - Subentity lookups

// Rows are keyed by their concrete kind (RptqDocumentElementLabel), so a query for
// the table-owning base entity must return rows of every kind that shares the
// table.  This is the test that fails if the plural lookup ever narrows to exact
// names again: it asserts a count, not just non-emptiness, so a lookup that
// silently returned nothing cannot pass.
- (void)testBaseEntityQueryReturnsRowsOfMixedKinds {
	RptqStoreContext *context = [self openContextAtPath:@"subentities.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *base = [context insertObjectForEntity:@"RptqDocumentElement" identifier:1];
	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:2];
	XCTAssertEqualObjects(base.entity, @"RptqDocumentElement");
	XCTAssertEqualObjects(label.entity, @"RptqDocumentElementLabel");
	XCTAssertTrue([context save:NULL]);

	// A fresh context is a real read from disk, where the rows are keyed by their
	// stored kind.
	RptqStoreContext *reread = [self openContextAtPath:@"subentities.sqlite"];
	XCTAssertTrue([reread loadAllWithError:NULL]);

	NSArray *elements = [reread objectsForEntity:@"RptqDocumentElement"];
	XCTAssertEqual(elements.count, (NSUInteger)2,
				   @"the base-entity query must return the label row too");
	NSArray *identifiers = [[elements valueForKey:@"identifier"] sortedArrayUsingSelector:@selector(compare:)];
	XCTAssertEqualObjects(identifiers, (@[ @1, @2 ]));

	// The graph-level lookup the context iterates has the same fallback.
	NSArray *rows = [[reread.store allObjectsWithError:NULL] objectsForEntity:@"RptqDocumentElement"];
	XCTAssertEqual(rows.count, (NSUInteger)2, @"the graph's plural lookup has the table fallback");
}

#pragma mark - Identifier minting

/// CONTRACT: minting happens per table, not per entity.  The element kinds share
/// RptqDocumentElement's table, so a kind inserting with identifier 0 while a
/// sibling kind already holds 5 must come back past 5 -- minting over the
/// requested kind alone would collide with the row already in the table.
- (void)testSubentityInsertMintsPastSiblingKindsInTheSharedTable {
	RptqStoreContext *context = [self openContextAtPath:@"mint-subentity.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:5];
	XCTAssertNotNil(label);

	RptqObject *chart = [context insertObjectForEntity:@"RptqDocumentElementChart" identifier:0];
	XCTAssertNotNil(chart);
	XCTAssertGreaterThan(chart.identifier, (int64_t)5);
	XCTAssertNotEqual(chart.identifier, label.identifier);
}

/// CONTRACT: an entity that owns its table still mints past its own table's
/// maximum, as it always did.
- (void)testOwnerEntityInsertStillMintsPastItsTableMaximum {
	RptqStoreContext *context = [self openContextAtPath:@"mint-owner.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *first = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:7];
	XCTAssertNotNil(first);

	RptqObject *second = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:0];
	XCTAssertNotNil(second);
	XCTAssertGreaterThan(second.identifier, (int64_t)7);
	XCTAssertNotEqual(second.identifier, first.identifier);
}

#pragma mark - Dirty tracking

/// Builds a small schema family -- the same rows the import flow builds -- and
/// leaves it saved, so the dirty-tracking tests start from a clean store.
- (RptqStoreContext *)savedContextAtPath:(NSString *)name {
	RptqStoreContext *context = [self openContextAtPath:name];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];

	RptqObject *customers = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[customers setValue:@"customers" forKey:@"name"];
	RptqObject *invoices = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	[invoices setValue:@"invoices" forKey:@"name"];
	[database setValue:@[ customers, invoices ] forKey:@"hasTables"];

	RptqObject *idField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[idField setValue:@"id" forKey:@"name"];
	RptqObject *nameField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[nameField setValue:@"name" forKey:@"name"];
	[customers setValue:@[ idField, nameField ] forKey:@"hasFields"];

	XCTAssertTrue([context save:NULL]);
	XCTAssertFalse(context.hasChanges, @"a saved context is clean");
	return context;
}

- (void)testHasChangesTracksInsertEditAndSave {
	RptqStoreContext *context = [self openContextAtPath:@"dirty.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	XCTAssertFalse(context.hasChanges, @"a freshly loaded context has no changes");

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	XCTAssertTrue(context.hasChanges, @"an insert is a change");

	XCTAssertTrue([context save:NULL]);
	XCTAssertFalse(context.hasChanges, @"a save clears the change set");

	[database setValue:@"Changed driver" forKey:@"databaseDriverType"];
	XCTAssertTrue(context.hasChanges, @"an attribute set is a change");
	XCTAssertTrue([context save:NULL]);
	XCTAssertFalse(context.hasChanges, @"a save clears the change set");
}

- (void)testSettingTheSameValueDoesNotDirtyTheRow {
	RptqStoreContext *context = [self savedContextAtPath:@"same-value.sqlite"];
	RptqObject *customers = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];

	[customers setValue:@"customers" forKey:@"name"]; // Already the value.
	XCTAssertFalse(context.hasChanges, @"setting the same value is not a change");

	[customers setValue:@"renamed" forKey:@"name"];
	XCTAssertTrue(context.hasChanges, @"setting a new value is a change");
}

- (void)testACleanSaveLeavesTheStoreFileUntouched {
	RptqStoreContext *context = [self savedContextAtPath:@"clean-save.sqlite"];
	NSURL *storeURL = context.store.url;

	NSDate *before = [[NSFileManager defaultManager] attributesOfItemAtPath:storeURL.path error:NULL][NSFileModificationDate];
	[NSThread sleepForTimeInterval:1.1]; // The modification date has 1-second granularity.
	XCTAssertTrue([context save:NULL]);
	NSDate *after = [[NSFileManager defaultManager] attributesOfItemAtPath:storeURL.path error:NULL][NSFileModificationDate];

	XCTAssertEqualObjects(before, after, @"a clean save must not touch the store file");
}

- (void)testOnePropertyChangeWritesOnlyThatRow {
	RptqStoreContext *context = [self savedContextAtPath:@"one-row.sqlite"];

	// The row before the edit, and everything the store holds.
	RptqObject *invoices = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	MADStoreGraph *expected = [context.store allObjectsWithError:NULL];

	[invoices setValue:@"invoices-renamed" forKey:@"name"];
	XCTAssertTrue([context save:NULL]);

	MADStoreGraph *actual = [context.store allObjectsWithError:NULL];
	for (MADStoreObject *row in [actual allObjects]) {
		MADStoreObject *before = [expected objectForEntity:row.entity identifier:row.identifier];
		XCTAssertNotNil(before, @"%@ %lld appeared out of nowhere", row.entity, (long long)row.identifier);
		if (row.identifier == 12 && [row.entity isEqualToString:@"RptqDatabaseSchemaTable"]) {
			XCTAssertEqualObjects([row attributeValue:@"name"], @"invoices-renamed");
		} else {
			XCTAssertTrue([row isEqualToObject:before], @"%@ %lld changed but should not have",
						  row.entity, (long long)row.identifier);
		}
	}
}

- (void)testAnOrderedToManyReorderIsWrittenIncrementally {
	RptqStoreContext *context = [self savedContextAtPath:@"ordered.sqlite"];
	RptqObject *customers = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];

	// Reverse the ordered field list on the owning side; the context maintains the
	// inverses, and the positions land on the field rows.
	[customers setValue:@[ [context objectForEntity:@"RptqDatabaseSchemaField" identifier:21],
						   [context objectForEntity:@"RptqDatabaseSchemaField" identifier:20] ]
				forKey:@"hasFields"];
	XCTAssertTrue([context save:NULL]);

	// A fresh read must come back in the new order.
	RptqStoreContext *reread = [self openContextAtPath:@"ordered.sqlite"];
	XCTAssertTrue([reread loadAllWithError:NULL]);
	NSOrderedSet *readBack = [[reread objectForEntity:@"RptqDatabaseSchemaTable" identifier:11] valueForKey:@"hasFields"];
	NSArray *identifiers = [readBack.array valueForKey:@"identifier"];
	XCTAssertEqualObjects(identifiers, (@[ @21, @20 ]), @"the reorder did not survive the incremental save");
}

- (void)testDeleteIsPendingUntilSave {
	RptqStoreContext *context = [self savedContextAtPath:@"delete.sqlite"];
	RptqObject *invoices = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12];

	XCTAssertTrue([context deleteObject:invoices error:NULL]);
	XCTAssertTrue(context.hasChanges, @"a pending delete is a change");

	// Pending: the row is still in the file until the save commits.
	XCTAssertNotNil([context.store objectForEntity:@"RptqDatabaseSchemaTable" identifier:12 error:NULL]);

	XCTAssertTrue([context save:NULL]);
	XCTAssertFalse(context.hasChanges, @"the save commits the delete");
	XCTAssertNil([context.store objectForEntity:@"RptqDatabaseSchemaTable" identifier:12 error:NULL],
				 @"the deleted row is gone after the save");
	XCTAssertNil([context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12],
				 @"the deleted row left the context's graph");
}

#pragma mark - Composition graph (store revision 3)

- (void)testCompositionGraphRoundTripsAndIsRevision3 {
	RptqStoreContext *context = [self openContextAtPath:@"composed.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];

	RptqObject *invoicesTable = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[invoicesTable setValue:@"invoices" forKey:@"name"];
	RptqObject *paymentsTable = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	[paymentsTable setValue:@"payments" forKey:@"name"];
	RptqObject *invoiceIdField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[invoiceIdField setValue:@"invoice_id" forKey:@"name"];
	RptqObject *amountField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[amountField setValue:@"amount" forKey:@"name"];
	[database setValue:@[ invoicesTable, paymentsTable ] forKey:@"hasTables"];
	[invoicesTable setValue:@[ invoiceIdField, amountField ] forKey:@"hasFields"];
	[paymentsTable setValue:@[ invoiceIdField, amountField ] forKey:@"hasFields"];

	RptqObject *rootQuery = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[rootQuery setValue:@"root" forKey:@"name"];
	RptqObject *invoicesQuery = [context insertObjectForEntity:@"RptqQuery" identifier:101];
	[invoicesQuery setValue:@"invoices" forKey:@"name"];
	RptqObject *paymentsQuery = [context insertObjectForEntity:@"RptqQuery" identifier:102];
	[paymentsQuery setValue:@"payments" forKey:@"name"];
	[database setValue:@[ rootQuery, invoicesQuery, paymentsQuery ] forKey:@"hasQueries"];

	RptqObject *invoicesSourceTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[invoicesSourceTable setValue:invoicesTable forKey:@"databaseSchemaTable"];
	[invoicesSourceTable setValue:invoicesQuery forKey:@"inQuery"];
	RptqObject *paymentsSourceTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:201];
	[paymentsSourceTable setValue:paymentsTable forKey:@"databaseSchemaTable"];
	[paymentsSourceTable setValue:paymentsQuery forKey:@"inQuery"];

	RptqObject *rootInvoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:202];
	[rootInvoicesTable setValue:rootQuery forKey:@"inQuery"];
	[rootInvoicesTable setValue:invoicesQuery forKey:@"upstreamQuery"];
	RptqObject *rootPaymentsTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:203];
	[rootPaymentsTable setValue:rootQuery forKey:@"inQuery"];
	[rootPaymentsTable setValue:paymentsQuery forKey:@"upstreamQuery"];

	RptqObject *leftKey = [context insertObjectForEntity:@"RptqQueryField" identifier:300];
	[leftKey setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[leftKey setValue:rootInvoicesTable forKey:@"inQueryTable"];
	RptqObject *rightKey = [context insertObjectForEntity:@"RptqQueryField" identifier:301];
	[rightKey setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[rightKey setValue:rootPaymentsTable forKey:@"inQueryTable"];

	RptqObject *join = [context insertObjectForEntity:@"RptqQueryLinks" identifier:400];
	[join setValue:@1 forKey:@"type"];
	[join setValue:leftKey forKey:@"hasLeftField"];
	[join setValue:rightKey forKey:@"hasRightField"];
	[join setValue:rootQuery forKey:@"inQuery"];

	[document setValue:rootQuery forKey:@"rootQuery"];

	NSError *error = nil;
	XCTAssertTrue([context saveComposed:&error], @"%@", error);
	XCTAssertEqual(context.store.storeVersion, MADStoreMaximumReadableVersion);

	RptqStoreContext *reread = [self openContextAtPath:@"composed.sqlite"];
	XCTAssertTrue([reread loadAllWithError:&error], @"%@", error);
	XCTAssertEqual(reread.store.storeVersion, MADStoreMaximumReadableVersion);

	RptqObject *readDocument = [reread objectForEntity:@"RptqDocument" identifier:1];
	RptqObject *readRoot = [readDocument valueForKey:@"rootQuery"];
	XCTAssertNotNil(readRoot);
	XCTAssertEqualObjects([readRoot valueForKey:@"name"], @"root");

	RptqObject *readDatabase = [[readDocument valueForKey:@"hasDatabaseSchemas"] anyObject];
	NSSet *queries = [readDatabase valueForKey:@"hasQueries"];
	XCTAssertEqual(queries.count, (NSUInteger)3);
	RptqObject *readInvoices = nil, *readPayments = nil;
	for (RptqObject *query in queries) {
		XCTAssertEqualObjects([[query valueForKey:@"inDatabase"] valueForKey:@"databaseDriverType"], @"Sqlite 3");
		if ([[query valueForKey:@"name"] isEqualToString:@"invoices"]) readInvoices = query;
		if ([[query valueForKey:@"name"] isEqualToString:@"payments"]) readPayments = query;
	}
	XCTAssertNotNil(readInvoices);
	XCTAssertNotNil(readPayments);

	NSSet *rootTables = [readRoot valueForKey:@"hasQueryTables"];
	XCTAssertEqual(rootTables.count, (NSUInteger)2);
	NSSet *rootUpstreams = [NSSet setWithArray:[[rootTables allObjects] valueForKey:@"upstreamQuery"]];
	XCTAssertEqual(rootUpstreams.count, (NSUInteger)2);

	NSSet *joinSet = [readRoot valueForKey:@"hasQueryLinks"];
	XCTAssertEqual(joinSet.count, (NSUInteger)1);
	RptqObject *readJoin = joinSet.anyObject;
	XCTAssertEqualObjects([readJoin valueForKey:@"type"], @1);
	XCTAssertEqualObjects([[[readJoin valueForKey:@"hasLeftField"] valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"invoice_id");
	XCTAssertEqualObjects([[[readJoin valueForKey:@"hasRightField"] valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"invoice_id");
}

#pragma mark - Importing a query graph

/// Builds an ordinary single-query graph -- one database, its credential, one schema
/// table and field, and one query with a query table and field -- using fixed
/// identifiers so two independent documents collide exactly.
- (void)buildStandardQueryGraphInContext:(RptqStoreContext *)context
							  tableName:(NSString *)tableName
							  fieldName:(NSString *)fieldName
								   host:(NSString *)host {
	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[database setValue:@10 forKey:@"databaseDriverTypeEnum"];
	RptqObject *credential = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];
	[credential setValue:host.lastPathComponent forKey:@"dbname"];
	[credential setValue:host forKey:@"host"];
	[database setValue:credential forKey:@"ownedByUser"];
	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[table setValue:tableName forKey:@"name"];
	RptqObject *field = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[field setValue:fieldName forKey:@"name"];
	[database setValue:@[ table ] forKey:@"hasTables"];
	[table setValue:@[ field ] forKey:@"hasFields"];
	RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[query setValue:database forKey:@"inDatabase"];
	RptqObject *queryTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[queryTable setValue:table forKey:@"databaseSchemaTable"];
	[queryTable setValue:query forKey:@"inQuery"];
	RptqObject *queryField = [context insertObjectForEntity:@"RptqQueryField" identifier:300];
	[queryField setValue:field forKey:@"databaseSchemaField"];
	[queryField setValue:queryTable forKey:@"inQueryTable"];
	[queryTable setValue:@[ queryField ] forKey:@"hasQueryFields"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
	[database setValue:@[ query ] forKey:@"hasQueries"];
}

- (void)testImportQueryGraphRemapsIdentifiersAndResolvesRelativePath {
	// Source and destination use the same identifiers, so nothing would coexist
	// without the remap.
	RptqStoreContext *source = [self openContextAtPath:@"source.sqlite"];
	XCTAssertTrue([source loadAllWithError:NULL]);
	[self buildStandardQueryGraphInContext:source tableName:@"invoices" fieldName:@"amount" host:@"invoices.sqlite"];
	NSError *sourceSaveError = nil;
	XCTAssertTrue([source save:&sourceSaveError], @"source save failed: %@", sourceSaveError);

	RptqStoreContext *destination = [self openContextAtPath:@"destination.sqlite"];
	XCTAssertTrue([destination loadAllWithError:NULL]);
	[self buildStandardQueryGraphInContext:destination tableName:@"orders" fieldName:@"total" host:@"orders.sqlite"];
	NSError *destinationSaveError = nil;
	XCTAssertTrue([destination save:&destinationSaveError], @"destination save failed: %@", destinationSaveError);

	NSURL *childURL = [self.directory URLByAppendingPathComponent:@"child.mad"];
	NSError *error = nil;
	RptqQuery *importedRoot = [destination importQueryGraphFromContext:source
												 relativePathBaseURL:childURL
																error:&error];
	XCTAssertNotNil(importedRoot, @"import failed: %@", error);
	XCTAssertNotEqual(importedRoot.identifier, (int64_t)100, @"the imported query must be remapped");

	// Two queries, two databases, two tables, two fields -- the originals plus the
	// imported copies.
	XCTAssertEqual([destination objectsForEntity:@"RptqQuery"].count, (NSUInteger)2);
	XCTAssertEqual([destination objectsForEntity:@"RptqDatabase"].count, (NSUInteger)2);
	XCTAssertEqual([destination objectsForEntity:@"RptqDatabaseSchemaTable"].count, (NSUInteger)2);
	XCTAssertEqual([destination objectsForEntity:@"RptqDatabaseSchemaField"].count, (NSUInteger)2);
	XCTAssertEqual([destination objectsForEntity:@"RptqQueryTable"].count, (NSUInteger)2);
	XCTAssertEqual([destination objectsForEntity:@"RptqQueryField"].count, (NSUInteger)2);

	// The imported query wires to its own imported database, schema table, and field.
	RptqObject *importedDatabase = [importedRoot valueForKey:@"inDatabase"];
	XCTAssertNotEqual(importedDatabase.identifier, (int64_t)10);
	NSSet *importedTables = [importedDatabase valueForKey:@"hasTables"];
	XCTAssertEqual(importedTables.count, (NSUInteger)1);
	RptqObject *importedTable = importedTables.anyObject;
	XCTAssertEqualObjects([importedTable valueForKey:@"name"], @"invoices");
	RptqObject *importedField = [[importedTable valueForKey:@"hasFields"] firstObject];
	XCTAssertEqualObjects([importedField valueForKey:@"name"], @"amount");

	RptqObject *importedQueryTable = [[importedRoot valueForKey:@"hasQueryTables"] anyObject];
	XCTAssertNotNil(importedQueryTable);
	RptqObject *importedQueryField = [[importedQueryTable valueForKey:@"hasQueryFields"] anyObject];
	XCTAssertNotNil(importedQueryField);
	XCTAssertEqualObjects([[importedQueryField valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"amount");
	XCTAssertEqualObjects([[importedQueryTable valueForKey:@"databaseSchemaTable"] valueForKey:@"name"], @"invoices");

	// The relative SQLite path resolves against the child's location.
	RptqObject *importedCredential = [importedDatabase valueForKey:@"ownedByUser"];
	XCTAssertEqualObjects([importedCredential valueForKey:@"host"],
						  [childURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"invoices.sqlite"].path);

	// The source is untouched: its identifiers did not move.
	RptqObject *sourceQuery = [source objectForEntity:@"RptqQuery" identifier:100];
	XCTAssertNotNil(sourceQuery);
	RptqObject *sourceTable = [[[sourceQuery valueForKey:@"inDatabase"] valueForKey:@"hasTables"] anyObject];
	XCTAssertEqualObjects([sourceTable valueForKey:@"name"], @"invoices");
}

- (void)testImportComposedGraphBringsRootAndLeaves {
	RptqStoreContext *source = [self openContextAtPath:@"composed-source.sqlite"];
	XCTAssertTrue([source loadAllWithError:NULL]);

	RptqObject *document = [source insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [source insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	RptqObject *invoicesTable = [source insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[invoicesTable setValue:@"invoices" forKey:@"name"];
	RptqObject *paymentsTable = [source insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	[paymentsTable setValue:@"payments" forKey:@"name"];
	RptqObject *invoiceIdField = [source insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[invoiceIdField setValue:@"invoice_id" forKey:@"name"];
	[database setValue:@[ invoicesTable, paymentsTable ] forKey:@"hasTables"];
	[invoicesTable setValue:@[ invoiceIdField ] forKey:@"hasFields"];
	[paymentsTable setValue:@[ invoiceIdField ] forKey:@"hasFields"];

	RptqObject *rootQuery = [source insertObjectForEntity:@"RptqQuery" identifier:100];
	[rootQuery setValue:@"root" forKey:@"name"];
	RptqObject *invoicesQuery = [source insertObjectForEntity:@"RptqQuery" identifier:101];
	[invoicesQuery setValue:@"invoices" forKey:@"name"];
	RptqObject *paymentsQuery = [source insertObjectForEntity:@"RptqQuery" identifier:102];
	[paymentsQuery setValue:@"payments" forKey:@"name"];
	[database setValue:@[ rootQuery, invoicesQuery, paymentsQuery ] forKey:@"hasQueries"];

	RptqObject *invoicesSourceTable = [source insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[invoicesSourceTable setValue:invoicesTable forKey:@"databaseSchemaTable"];
	[invoicesSourceTable setValue:invoicesQuery forKey:@"inQuery"];
	RptqObject *paymentsSourceTable = [source insertObjectForEntity:@"RptqQueryTable" identifier:201];
	[paymentsSourceTable setValue:paymentsTable forKey:@"databaseSchemaTable"];
	[paymentsSourceTable setValue:paymentsQuery forKey:@"inQuery"];

	RptqObject *rootInvoicesTable = [source insertObjectForEntity:@"RptqQueryTable" identifier:202];
	[rootInvoicesTable setValue:rootQuery forKey:@"inQuery"];
	[rootInvoicesTable setValue:invoicesQuery forKey:@"upstreamQuery"];
	RptqObject *rootPaymentsTable = [source insertObjectForEntity:@"RptqQueryTable" identifier:203];
	[rootPaymentsTable setValue:rootQuery forKey:@"inQuery"];
	[rootPaymentsTable setValue:paymentsQuery forKey:@"upstreamQuery"];

	[document setValue:rootQuery forKey:@"rootQuery"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
	XCTAssertTrue([source saveComposed:NULL]);

	RptqStoreContext *destination = [self openContextAtPath:@"composed-destination.sqlite"];
	XCTAssertTrue([destination loadAllWithError:NULL]);
	RptqObject *destinationDocument = [destination insertObjectForEntity:@"RptqDocument" identifier:1];

	NSError *error = nil;
	RptqQuery *importedRoot = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:&error];
	XCTAssertNotNil(importedRoot, @"import failed: %@", error);
	XCTAssertEqualObjects([importedRoot valueForKey:@"name"], @"root");

	// The whole graph came along: root + two leaves, and the two schema tables.
	XCTAssertEqual([destination objectsForEntity:@"RptqQuery"].count, (NSUInteger)3);
	XCTAssertEqual([destination objectsForEntity:@"RptqDatabaseSchemaTable"].count, (NSUInteger)2);

	NSSet *importedRootTables = [importedRoot valueForKey:@"hasQueryTables"];
	XCTAssertEqual(importedRootTables.count, (NSUInteger)2);
	NSMutableSet *upstreamNames = [NSMutableSet set];
	for (RptqObject *table in importedRootTables) {
		RptqObject *upstream = [table valueForKey:@"upstreamQuery"];
		XCTAssertNotNil(upstream);
		[upstreamNames addObject:[upstream valueForKey:@"name"]];
	}
	XCTAssertEqualObjects(upstreamNames, ([NSSet setWithArray:@[ @"invoices", @"payments" ]]));

	// The imported root is not the destination document's root (that relationship is
	// not copied across the import).
	XCTAssertNil([destinationDocument valueForKey:@"rootQuery"]);
}

#pragma mark - Composed output-key naming

- (RptqQueryField *)fieldWithSchemaName:(NSString *)schemaName
						   sourceAlias:(NSString *)sourceAlias
								context:(RptqStoreContext *)context {
	RptqObject *schemaField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:0];
	[schemaField setValue:schemaName forKey:@"name"];
	RptqObject *upstream = [context insertObjectForEntity:@"RptqQuery" identifier:0];
	[upstream setValue:sourceAlias forKey:@"name"];
	RptqObject *table = [context insertObjectForEntity:@"RptqQueryTable" identifier:0];
	[table setValue:upstream forKey:@"upstreamQuery"];
	RptqQueryField *field = (RptqQueryField *)[context insertObjectForEntity:@"RptqQueryField" identifier:0];
	[field setValue:schemaField forKey:@"databaseSchemaField"];
	[field setValue:table forKey:@"inQueryTable"];
	return field;
}

- (void)testComposeOutputKeysBareNamesDisambiguate {
	RptqStoreContext *context = [self openContextAtPath:@"naming.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqQueryField *invoiceId = [self fieldWithSchemaName:@"invoice_id" sourceAlias:@"invoices" context:context];
	RptqQueryField *invoiceAmount = [self fieldWithSchemaName:@"amount" sourceAlias:@"invoices" context:context];
	RptqQueryField *paymentAmount = [self fieldWithSchemaName:@"amount" sourceAlias:@"payments" context:context];

	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:@[ invoiceId, invoiceAmount, paymentAmount ]
														 existingKeys:[NSSet set]];
	XCTAssertEqualObjects(keys, (@[ @"invoice_id", @"invoices.amount", @"payments.amount" ]));
}

- (void)testComposeOutputKeysPreserveExistingAndAvoidTaken {
	RptqStoreContext *context = [self openContextAtPath:@"naming2.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqQueryField *kept = [self fieldWithSchemaName:@"amount" sourceAlias:@"invoices" context:context];
	kept.outputKey = @"kept_amount";
	RptqQueryField *newAmount = [self fieldWithSchemaName:@"amount" sourceAlias:@"payments" context:context];

	// The preserved key survives; the new field's bare name is unique among the
	// unnamed fields, so it stays bare.
	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:@[ kept, newAmount ]
														 existingKeys:[NSSet set]];
	XCTAssertEqualObjects(keys, (@[ @"kept_amount", @"amount" ]));

	// A bare name already taken elsewhere is qualified with the source alias.
	RptqQueryField *colliding = [self fieldWithSchemaName:@"amount" sourceAlias:@"payments" context:context];
	NSArray<NSString *> *keys2 = [RptqQuery composeOutputKeysForFields:@[ colliding ]
														 existingKeys:[NSSet setWithArray:@[ @"amount" ]]];
	XCTAssertEqualObjects(keys2, (@[ @"payments.amount" ]));
}

#pragma mark - Converting a standard report to a composition

- (void)testConvertToCompositionMovesGroupsAndRebindsLabels {
	RptqStoreContext *context = [self openContextAtPath:@"convert.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	// A standard report: one database, one table with two fields, one query.
	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[table setValue:@"invoices" forKey:@"name"];
	RptqObject *invoiceIdField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[invoiceIdField setValue:@"invoice_id" forKey:@"name"];
	RptqObject *amountField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[amountField setValue:@"amount" forKey:@"name"];
	[database setValue:@[ table ] forKey:@"hasTables"];
	[table setValue:@[ invoiceIdField, amountField ] forKey:@"hasFields"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];

	RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[query setValue:database forKey:@"inDatabase"];
	RptqObject *queryTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[queryTable setValue:table forKey:@"databaseSchemaTable"];
	[queryTable setValue:query forKey:@"inQuery"];
	RptqObject *invoiceIdQueryField = [context insertObjectForEntity:@"RptqQueryField" identifier:300];
	[invoiceIdQueryField setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[invoiceIdQueryField setValue:queryTable forKey:@"inQueryTable"];
	RptqObject *amountQueryField = [context insertObjectForEntity:@"RptqQueryField" identifier:301];
	[amountQueryField setValue:amountField forKey:@"databaseSchemaField"];
	[amountQueryField setValue:queryTable forKey:@"inQueryTable"];
	[queryTable setValue:@[ invoiceIdQueryField, amountQueryField ] forKey:@"hasQueryFields"];

	// A group on invoice_id, and a data label bound to amount.
	RptqObject *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:400];
	[group setValue:invoiceIdQueryField forKey:@"hasField"];
	[group setValue:@1 forKey:@"sort"];
	[group setValue:@0 forKey:@"weight"];
	[group setValue:query forKey:@"inQuery"];
	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	[label setValue:amountQueryField forKey:@"referencesQueryField"];

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	NSError *error = nil;
	RptqQuery *root = [model convertToCompositionWithChildName:@"invoices" error:&error];
	XCTAssertNotNil(root, @"convert failed: %@", error);
	XCTAssertEqualObjects([model valueForKey:@"rootQuery"], root);
	XCTAssertEqualObjects([root valueForKey:@"name"], @"root");

	// The child is named, and its groups are gone.
	RptqObject *child = [model valueForKey:@"mainQuery"];
	XCTAssertEqualObjects([child valueForKey:@"name"], @"invoices");
	XCTAssertEqual([[child valueForKey:@"hasQueryGroups"] count], (NSUInteger)0);

	// The root has one upstream table and two projected fields with output keys.
	NSSet *rootTables = [root valueForKey:@"hasQueryTables"];
	XCTAssertEqual(rootTables.count, (NSUInteger)1);
	RptqObject *rootTable = rootTables.anyObject;
	XCTAssertNotNil([rootTable valueForKey:@"upstreamQuery"]);
	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:&error];
	XCTAssertEqual(outputs.count, (NSUInteger)2);
	XCTAssertEqualObjects(outputs[0].outputKey, @"invoice_id");
	XCTAssertEqualObjects(outputs[1].outputKey, @"amount");

	// The group moved to the root and binds to the root's invoice_id output.
	NSSet *rootGroups = [root valueForKey:@"hasQueryGroups"];
	XCTAssertEqual(rootGroups.count, (NSUInteger)1);
	RptqObject *rootGroup = rootGroups.anyObject;
	XCTAssertEqualObjects([[rootGroup valueForKey:@"hasField"] valueForKey:@"outputKey"], @"invoice_id");

	// The label rebinds to the root's amount output, not the child field.
	RptqObject *rebound = [label valueForKey:@"referencesQueryField"];
	XCTAssertNotEqual(rebound.identifier, [amountQueryField valueForKey:@"identifier"]);
	XCTAssertEqualObjects([rebound valueForKey:@"outputKey"], @"amount");
}

- (void)testOrdinaryReportStaysRevision2 {
	RptqStoreContext *context = [self openContextAtPath:@"ordinary.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[table setValue:@"invoices" forKey:@"name"];
	[database setValue:@[ table ] forKey:@"hasTables"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
	RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[query setValue:database forKey:@"inDatabase"];

	NSError *error = nil;
	XCTAssertTrue([context save:&error], @"%@", error);
	XCTAssertEqual(context.store.storeVersion, MADStoreCurrentVersion);

	RptqStoreContext *reread = [self openContextAtPath:@"ordinary.sqlite"];
	XCTAssertTrue([reread loadAllWithError:&error], @"%@", error);
	XCTAssertEqual(reread.store.storeVersion, MADStoreCurrentVersion);
	XCTAssertNil([[reread objectForEntity:@"RptqDocument" identifier:1] valueForKey:@"rootQuery"]);
}

- (void)testFailedCompositionSaveRollsBackToRevision2 {
	NSURL *url = [self.directory URLByAppendingPathComponent:@"failed.sqlite"];
	MADStore *store = [MADStore storeWithURL:url];
	XCTAssertTrue([store openWithError:NULL]);

	MADStoreObject *document = [MADStoreObject objectWithEntity:@"RptqDocument" identifier:1];
	[document setReference:@100 forName:@"rootQuery"];
	MADStoreObject *query = [MADStoreObject objectWithEntity:@"RptqQuery" identifier:100];
	[query setAttributeValue:@"root" forName:@"name"];
	MADStoreObject *bad = [MADStoreObject objectWithEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[bad setAttributeValue:@1 forName:@"identifier"];

	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:document];
	[graph addObject:query];
	[graph addObject:bad];

	NSError *error = nil;
	XCTAssertFalse([store writeGraph:graph replacingAll:NO composed:YES error:&error]);
	XCTAssertEqual(store.storeVersion, MADStoreCurrentVersion);
	[store close];

	MADStore *reread = [MADStore storeWithURL:url];
	XCTAssertTrue([reread openWithError:NULL]);
	XCTAssertEqual(reread.storeVersion, MADStoreCurrentVersion);
	[reread close];
}

@end
