//
//  RptqStoreContextTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
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

@end
