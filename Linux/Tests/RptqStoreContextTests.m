//
//  RptqStoreContextTests.m
//  Linux/Tests
//
//  Ported from MADTests/RptqStoreContextTests.m: coverage for the Phase C
//  mechanism -- the plain store-backed RptqObject and the RptqStoreContext that
//  replaces the NSManagedObjectContext role.  The schema family is the proof: it
//  round-trips through the context exactly the way
//  MADOperationCreateDocumentImportSchema builds it.  The Xcode setUp/tearDown pair
//  is a fresh temp directory per test here.
//
//  The original's two converted-sample tests need MADStoreConverter -- an app-side,
//  Core Data-backed converter -- and the London.mad test resource, none of which is
//  in the Linux subset, so those tests report a need (see their section).
//

#import "MADTestSupport.h"

#import <MAD/RptqObject.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADStore.h>

// The original imported "MADStoreConverter.h" for the converted-sample tests; that
// header is app-side and Core Data-backed and does not exist off Apple.

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

#pragma mark - Fixture helpers

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

static void removeTempDirectory(NSURL *directory) {
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

// Stands in for the Xcode suite's -openContextAtPath: over its setUp directory.
static RptqStoreContext *openContextAtPath(NSURL *directory, NSString *name) {
	NSURL *url = [directory URLByAppendingPathComponent:name];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "open failed: %s", [[error description] UTF8String]);
	return [RptqStoreContext contextWithStore:store];
}

#pragma mark - The schema family, round-tripped

/// Builds the same schema the import flow does -- a document, one database, its
/// credentials, and tables with ordered fields -- through the context, saves, reopens
/// from disk, and asserts every attribute and edge survived in both directions.
static void testSchemaRoundTripsThroughTheContext(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"schema.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

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
	MAD_PASS([context save:&error], "save failed: %s", [[error description] UTF8String]);

	// A fresh context over the same file is a real read-from-disk, not the in-memory
	// registry.
	RptqStoreContext *reread = openContextAtPath(directory, @"schema.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "load failed: %s", [[error description] UTF8String]);

	RptqObject *readDocument = [reread objectForEntity:@"RptqDocument" identifier:1];
	MAD_PASS(readDocument != nil, "the document is read back");
	NSSet *databases = [readDocument valueForKey:@"hasDatabaseSchemas"];
	MAD_PASS(databases.count == (NSUInteger)1, "the document owns one database");

	RptqObject *readDatabase = databases.anyObject;
	MAD_PASS(readDatabase.identifier == (int64_t)10, "the database identifier survives the round trip");
	MAD_PASS_EQUAL([readDatabase valueForKey:@"databaseDriverType"], @"Sqlite 3", "the driver type survives the round trip");
	MAD_PASS_EQUAL([readDatabase valueForKey:@"databaseDriverTypeEnum"], @2, "the driver type enum survives the round trip");

	// The credential came back minted a non-zero identifier, and both directions of
	// the one-to-one hold.
	RptqObject *readCredential = [readDatabase valueForKey:@"ownedByUser"];
	MAD_PASS(readCredential != nil, "the credential is read back");
	MAD_PASS(readCredential.identifier > (int64_t)0, "the credential identifier was minted");
	RptqObject *credentialDatabase = [readCredential valueForKey:@"inDatabase"];
	MAD_PASS(credentialDatabase.identifier == readDatabase.identifier, "the inverse one-to-one edge is filled in");
	MAD_PASS_EQUAL([readCredential valueForKey:@"dbname"], @"chinook.sqlite3", "the credential dbname survives the round trip");

	NSSet *tables = [readDatabase valueForKey:@"hasTables"];
	MAD_PASS(tables.count == (NSUInteger)2, "the database owns two tables");

	RptqObject *readCustomers = nil;
	for (RptqObject *table in tables) {
		RptqObject *owningDatabase = [table valueForKey:@"inDatabase"];
		MAD_PASS(owningDatabase.identifier == readDatabase.identifier, "each table's owning database is the read database");
		if ([[table valueForKey:@"name"] isEqualToString:@"customers"]) readCustomers = table;
	}
	MAD_PASS(readCustomers != nil, "the customers table is among them");
	MAD_PASS_EQUAL([readCustomers valueForKey:@"queryable"], @YES, "the queryable flag survives the round trip");

	NSOrderedSet *fields = [readCustomers valueForKey:@"hasFields"];
	MAD_PASS(fields.count == (NSUInteger)3, "the customers table owns three fields");
	MAD_PASS_EQUAL([fields[0] valueForKey:@"name"], @"id", "the first field keeps its position");
	MAD_PASS_EQUAL([fields[1] valueForKey:@"name"], @"name", "the second field keeps its position");
	MAD_PASS_EQUAL([fields[2] valueForKey:@"name"], @"email", "the third field keeps its position");
	for (RptqObject *field in fields) {
		RptqObject *owningTable = [field valueForKey:@"inTable"];
		MAD_PASS(owningTable.identifier == readCustomers.identifier, "each field's owning table is the customers table");
	}

	removeTempDirectory(directory);
}

/// A context returns the same object for the same (entity, identifier), so identity
/// holds across faults -- what the app expects of an object graph.
static void testFaultingReturnsStableIdentities(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"identity.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	[context insertObjectForEntity:@"RptqDatabase" identifier:10];
	MAD_PASS([context save:NULL], "the row saves");

	RptqStoreContext *reread = openContextAtPath(directory, @"identity.sqlite");
	MAD_PASS([reread loadAllWithError:NULL], "the fresh context loads");

	RptqObject *first = [reread objectForEntity:@"RptqDatabase" identifier:10];
	RptqObject *second = [reread objectForEntity:@"RptqDatabase" identifier:10];
	MAD_PASS(first == second, "the context faults the same row to the same object");

	removeTempDirectory(directory);
}

/// The swapped classes keep @dynamic dot-syntax working: +resolveInstanceMethod: on the
/// base installs typed getters and setters that read and write the backing row.
static void testDynamicAccessorsServeDotSyntax(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"dynamic.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	MADStoreObject *backing = [MADStoreObject objectWithEntity:@"RptqDatabase" identifier:10];
	RptqDynamicAccessStub *stub = [RptqDynamicAccessStub objectWithBackingObject:backing storeContext:context];

	stub.databaseDriverType = @"Sqlite 3";
	stub.databaseDriverTypeEnum = 2;

	MAD_PASS_EQUAL(stub.databaseDriverType, @"Sqlite 3", "the dynamic object getter reads the row");
	MAD_PASS(stub.databaseDriverTypeEnum == (int16_t)2, "the dynamic scalar getter reads the row");
	MAD_PASS(stub.identifier == (int64_t)10, "the identifier is the backing row's");

	removeTempDirectory(directory);
}

#pragma mark - A real document

/// Reads the schema family back out of a converted shipping sample through the
/// mechanism, so the census and the edges are pinned to a real document rather than a
/// hand-built one.  The conversion needs MADStoreConverter, Core Data and the
/// London.mad resource; none exists off Apple.
static void testSchemaFamilyReadsBackFromAConvertedSample(void) {
	MAD_NEED(NO, @"the converted-sample fixture needs MADStoreConverter, Core Data and London.mad, none of which is in the Linux subset");
}

#pragma mark - The document path

/// The characterization pin for the MADDocument open/save rewire: a legacy Core Data
/// document is converted to the portable store on open, the store is written out again,
/// and reopening it hands back the same graph.  MADocument and MADStoreConverter are
/// both Apple-only; the store write it exercises is covered by the portable-store
/// suite.
static void testDocumentPathConvertsSavesAndReopensUnchanged(void) {
	MAD_NEED(NO, @"the document path needs MADocument and MADStoreConverter, both Apple-only (MADSources.cmake)");
}

#pragma mark - Change notification

// The context mirrors Core Data's change notification -- same name, object = the
// context, RptqStoreContextInsertedObjectsKey / RptqStoreContextUpdatedObjectsKey / RptqStoreContextDeletedObjectsKey --
// coalesced to one post per run-loop turn, so a gesture that sets many properties
// cannot storm the observers.
static void testChangeNotificationPostsCoalescedWithCoreDataKeys(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"notify.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	__block NSUInteger postCount = 0;
	__block NSNotification *received = nil;
	__block BOOL posted = NO;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:RptqStoreContextObjectsDidChangeNotification
																	object:context
																	 queue:[NSOperationQueue mainQueue]
																usingBlock:^(NSNotification *note) {
		postCount++;
		// MRC test translation unit: the block does not retain its captures.
		received = [note retain];
		posted = YES;
	}];

	// Many changes inside one turn: one notification for all of them.
	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:0];
	[table setValue:@"one" forKey:@"name"];
	[table setValue:@"two" forKey:@"name"];
	[table setValue:@"three" forKey:@"name"];
	RptqObject *second = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:0];
	[context deleteObject:second error:NULL];

	// The Xcode suite's waitForExpectations, on the harness's run-loop flag.
	MAD_PASS(MADWaitForFlag(&posted, 5.0), "the change notification arrives");

	NSSet *inserted = received.userInfo[RptqStoreContextInsertedObjectsKey];
	NSSet *updated = received.userInfo[RptqStoreContextUpdatedObjectsKey];
	NSSet *deleted = received.userInfo[RptqStoreContextDeletedObjectsKey];
	MAD_PASS(inserted != nil, "the notification carries the Core Data userInfo keys");
	MAD_PASS([inserted containsObject:table], "the inserted row is in RptqStoreContextInsertedObjectsKey");
	MAD_PASS([updated containsObject:table], "the changed row is in RptqStoreContextUpdatedObjectsKey");
	MAD_PASS([deleted containsObject:second], "the deleted row is in RptqStoreContextDeletedObjectsKey");
	MAD_PASS(![inserted containsObject:second], "a deleted insert leaves the inserted set");

	// A turn passes; the post count must still be one -- the burst coalesced.
	[NSThread sleepForTimeInterval:0.1];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	MAD_PASS(postCount == (NSUInteger)1, "one run-loop turn, one notification");

	[[NSNotificationCenter defaultCenter] removeObserver:observer];
	removeTempDirectory(directory);
}

#pragma mark - Schema lookup memoization

// The flattened arrays and name indexes are warmed once at schema construction and
// never rebuilt; the render path depends on that -- a fresh array per call is what
// blew the large-report export up to gigabytes.
static void testSchemaFlattenedArraysAreMemoizedAndStable(void) {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	for (MADStoreEntity *entity in schema.entities) {
		NSArray *attributes = entity.allAttributes;
		NSArray *relationships = entity.allRelationships;

		// Repeat calls return the same object -- the memoization, not just equal
		// content -- so the property layer allocates nothing per read.
		MAD_PASS(entity.allAttributes == attributes, "%s allAttributes reallocates", entity.name.UTF8String);
		MAD_PASS(entity.allRelationships == relationships, "%s allRelationships reallocates", entity.name.UTF8String);

		// The content is the ancestors' followed by the entity's own, and the name
		// indexes agree with the flattened arrays.
		if (entity.parentName != nil) {
			MADStoreEntity *parent = [schema entityNamed:entity.parentName];
			// A subentity may declare no attributes of its own (the chart kind), so
			// equality with the parent is legal; the tail check pins the rest.
			MAD_PASS(attributes.count >= parent.allAttributes.count,
					 "%s must flatten its ancestors' attributes", entity.name.UTF8String);
			NSArray *own = entity.attributes;
			NSArray *tail = [attributes subarrayWithRange:NSMakeRange(attributes.count - own.count, own.count)];
			MAD_PASS_EQUAL(tail, own, "%s ends with its own attributes", entity.name.UTF8String);
		} else {
			MAD_PASS(attributes == entity.attributes, "a table owner's allAttributes is its own list");
		}
		for (MADStoreAttribute *attribute in attributes) {
			MAD_PASS([entity anyAttributeNamed:attribute.name] == attribute,
					 "%s %s misses in the name index", entity.name.UTF8String, attribute.name.UTF8String);
		}
		for (MADStoreRelationship *relationship in relationships) {
			MAD_PASS([entity anyRelationshipNamed:relationship.name] == relationship,
					 "%s %s misses in the name index", entity.name.UTF8String, relationship.name.UTF8String);
		}
	}
}

#pragma mark - RptqObject KVC semantics

// The property layer's behaviour must not change with the memoized lookups: reads,
// setter dirty-marking, unknown-key raising, and subclass-inherited attributes all
// behave exactly as before.
static void testRptqObjectKVCSemanticsAreUnchanged(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"kvc.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:50];
	[table setValue:@"customers" forKey:@"name"];
	MAD_PASS_EQUAL([table valueForKey:@"name"], @"customers", "an attribute read");
	MAD_PASS([context save:NULL], "the row saves");
	MAD_PASS(!context.hasChanges, "a saved context is clean");

	[table setValue:@"renamed" forKey:@"name"];
	MAD_PASS_EQUAL([table valueForKey:@"name"], @"renamed", "the renamed attribute reads back");
	MAD_PASS(context.hasChanges, "an attribute set marks the row dirty");

	// A set to the same value is not a change.
	[table setValue:@"renamed" forKey:@"name"];
	MAD_PASS(context.hasChanges, "a same-value set leaves the change set as it was");

	// An unknown key still raises through NSObject.  GNUstep spells the exception
	// constant NSUndefinedKeyException; its value is the same NSUnknownKeyException
	// the Xcode suite asserts against.
	MAD_THROWS_NAMED([table valueForKey:@"noSuchKeyAtAll"], NSUndefinedKeyException, "an unknown key read raises through NSObject");
	MAD_THROWS_NAMED([table setValue:@1 forKey:@"noSuchKeyAtAll"], NSUndefinedKeyException, "an unknown key write raises through NSObject");

	// A subentity reads the base element's attributes through the flattened index.
	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:60];
	[label setValue:@2 forKey:@"type"];
	MAD_PASS_EQUAL([label valueForKey:@"type"], @2, "a subclass reads an inherited attribute");

	// A to-many relationship read returns the member objects.
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:70];
	[database setValue:@[ table ] forKey:@"hasTables"];
	NSSet *tables = [database valueForKey:@"hasTables"];
	MAD_PASS(tables.count == (NSUInteger)1, "the to-many read returns one member");
	MAD_PASS([tables containsObject:table], "a to-many read faults the member");

	removeTempDirectory(directory);
}

#pragma mark - Subentity lookups

// Rows are keyed by their concrete kind (RptqDocumentElementLabel), so a query for
// the table-owning base entity must return rows of every kind that shares the
// table.  This is the test that fails if the plural lookup ever narrows to exact
// names again: it asserts a count, not just non-emptiness, so a lookup that
// silently returned nothing cannot pass.
static void testBaseEntityQueryReturnsRowsOfMixedKinds(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"subentities.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *base = [context insertObjectForEntity:@"RptqDocumentElement" identifier:1];
	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:2];
	MAD_PASS_EQUAL(base.entity, @"RptqDocumentElement", "the base row carries its own kind");
	MAD_PASS_EQUAL(label.entity, @"RptqDocumentElementLabel", "the label row carries its own kind");
	MAD_PASS([context save:NULL], "the rows save");

	// A fresh context is a real read from disk, where the rows are keyed by their
	// stored kind.
	RptqStoreContext *reread = openContextAtPath(directory, @"subentities.sqlite");
	MAD_PASS([reread loadAllWithError:NULL], "the fresh context loads");

	NSArray *elements = [reread objectsForEntity:@"RptqDocumentElement"];
	MAD_PASS(elements.count == (NSUInteger)2, "the base-entity query must return the label row too");
	NSArray *identifiers = [[elements valueForKey:@"identifier"] sortedArrayUsingSelector:@selector(compare:)];
	MAD_PASS_EQUAL(identifiers, (@[ @1, @2 ]), "the base query returns the base row and the label row");

	// The graph-level lookup the context iterates has the same fallback.
	NSArray *rows = [[reread.store allObjectsWithError:NULL] objectsForEntity:@"RptqDocumentElement"];
	MAD_PASS(rows.count == (NSUInteger)2, "the graph's plural lookup has the table fallback");

	removeTempDirectory(directory);
}

#pragma mark - Identifier minting

/// CONTRACT: minting happens per table, not per entity.  The element kinds share
/// RptqDocumentElement's table, so a kind inserting with identifier 0 while a
/// sibling kind already holds 5 must come back past 5 -- minting over the
/// requested kind alone would collide with the row already in the table.
static void testSubentityInsertMintsPastSiblingKindsInTheSharedTable(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"mint-subentity.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *label = [context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:5];
	MAD_PASS(label != nil, "the label row inserts");

	RptqObject *chart = [context insertObjectForEntity:@"RptqDocumentElementChart" identifier:0];
	MAD_PASS(chart != nil, "the chart row inserts");
	MAD_PASS(chart.identifier > (int64_t)5, "the chart mints past the sibling kind's row");
	MAD_PASS(chart.identifier != label.identifier, "the two kinds do not share an identifier");

	removeTempDirectory(directory);
}

/// CONTRACT: an entity that owns its table still mints past its own table's
/// maximum, as it always did.
static void testOwnerEntityInsertStillMintsPastItsTableMaximum(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"mint-owner.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *first = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:7];
	MAD_PASS(first != nil, "the first field row inserts");

	RptqObject *second = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:0];
	MAD_PASS(second != nil, "the second field row inserts");
	MAD_PASS(second.identifier > (int64_t)7, "the second mints past the table maximum");
	MAD_PASS(second.identifier != first.identifier, "the two rows do not share an identifier");

	removeTempDirectory(directory);
}

#pragma mark - Dirty tracking

/// Builds a small schema family -- the same rows the import flow builds -- and
/// leaves it saved, so the dirty-tracking tests start from a clean store.
static RptqStoreContext *savedContextAtPath(NSURL *directory, NSString *name) {
	RptqStoreContext *context = openContextAtPath(directory, name);
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

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

	MAD_PASS([context save:NULL], "the context saves");
	MAD_PASS(!context.hasChanges, "a saved context is clean");
	return context;
}

static void testHasChangesTracksInsertEditAndSave(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"dirty.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	MAD_PASS(!context.hasChanges, "a freshly loaded context has no changes");

	[context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	MAD_PASS(context.hasChanges, "an insert is a change");

	MAD_PASS([context save:NULL], "the save succeeds");
	MAD_PASS(!context.hasChanges, "a save clears the change set");

	[database setValue:@"Changed driver" forKey:@"databaseDriverType"];
	MAD_PASS(context.hasChanges, "an attribute set is a change");
	MAD_PASS([context save:NULL], "the second save succeeds");
	MAD_PASS(!context.hasChanges, "a save clears the change set");

	removeTempDirectory(directory);
}

static void testSettingTheSameValueDoesNotDirtyTheRow(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = savedContextAtPath(directory, @"same-value.sqlite");
	RptqObject *customers = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];

	[customers setValue:@"customers" forKey:@"name"]; // Already the value.
	MAD_PASS(!context.hasChanges, "setting the same value is not a change");

	[customers setValue:@"renamed" forKey:@"name"];
	MAD_PASS(context.hasChanges, "setting a new value is a change");

	removeTempDirectory(directory);
}

static void testACleanSaveLeavesTheStoreFileUntouched(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = savedContextAtPath(directory, @"clean-save.sqlite");
	NSURL *storeURL = context.store.url;

	NSDate *before = [[NSFileManager defaultManager] attributesOfItemAtPath:storeURL.path error:NULL][NSFileModificationDate];
	[NSThread sleepForTimeInterval:1.1]; // The modification date has 1-second granularity.
	MAD_PASS([context save:NULL], "the clean save succeeds");
	NSDate *after = [[NSFileManager defaultManager] attributesOfItemAtPath:storeURL.path error:NULL][NSFileModificationDate];

	MAD_PASS_EQUAL(before, after, "a clean save must not touch the store file");

	removeTempDirectory(directory);
}

static void testOnePropertyChangeWritesOnlyThatRow(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = savedContextAtPath(directory, @"one-row.sqlite");

	// The row before the edit, and everything the store holds.
	RptqObject *invoices = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	MADStoreGraph *expected = [context.store allObjectsWithError:NULL];

	[invoices setValue:@"invoices-renamed" forKey:@"name"];
	MAD_PASS([context save:NULL], "the incremental save succeeds");

	MADStoreGraph *actual = [context.store allObjectsWithError:NULL];
	for (MADStoreObject *row in [actual allObjects]) {
		MADStoreObject *before = [expected objectForEntity:row.entity identifier:row.identifier];
		MAD_PASS(before != nil, "%s %lld appeared out of nowhere", row.entity.UTF8String, (long long)row.identifier);
		if (row.identifier == 12 && [row.entity isEqualToString:@"RptqDatabaseSchemaTable"]) {
			MAD_PASS_EQUAL([row attributeValue:@"name"], @"invoices-renamed", "the edited row carries the new name");
		} else {
			MAD_PASS([row isEqualToObject:before], "%s %lld changed but should not have",
					 row.entity.UTF8String, (long long)row.identifier);
		}
	}

	removeTempDirectory(directory);
}

static void testAnOrderedToManyReorderIsWrittenIncrementally(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = savedContextAtPath(directory, @"ordered.sqlite");
	RptqObject *customers = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:11];

	// Reverse the ordered field list on the owning side; the context maintains the
	// inverses, and the positions land on the field rows.
	[customers setValue:@[ [context objectForEntity:@"RptqDatabaseSchemaField" identifier:21],
						   [context objectForEntity:@"RptqDatabaseSchemaField" identifier:20] ]
				forKey:@"hasFields"];
	MAD_PASS([context save:NULL], "the reorder saves");

	// A fresh read must come back in the new order.
	RptqStoreContext *reread = openContextAtPath(directory, @"ordered.sqlite");
	MAD_PASS([reread loadAllWithError:NULL], "the fresh context loads");
	NSOrderedSet *readBack = [[reread objectForEntity:@"RptqDatabaseSchemaTable" identifier:11] valueForKey:@"hasFields"];
	NSArray *identifiers = [readBack.array valueForKey:@"identifier"];
	MAD_PASS_EQUAL(identifiers, (@[ @21, @20 ]), "the reorder did not survive the incremental save");

	removeTempDirectory(directory);
}

static void testDeleteIsPendingUntilSave(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = savedContextAtPath(directory, @"delete.sqlite");
	RptqObject *invoices = [context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12];

	MAD_PASS([context deleteObject:invoices error:NULL], "the delete is accepted");
	MAD_PASS(context.hasChanges, "a pending delete is a change");

	// Pending: the row is still in the file until the save commits.
	MAD_PASS([context.store objectForEntity:@"RptqDatabaseSchemaTable" identifier:12 error:NULL] != nil,
			 "the row is still in the file before the save");

	MAD_PASS([context save:NULL], "the save succeeds");
	MAD_PASS(!context.hasChanges, "the save commits the delete");
	MAD_PASS([context.store objectForEntity:@"RptqDatabaseSchemaTable" identifier:12 error:NULL] == nil,
			 "the deleted row is gone after the save");
	MAD_PASS([context objectForEntity:@"RptqDatabaseSchemaTable" identifier:12] == nil,
			 "the deleted row left the context's graph");

	removeTempDirectory(directory);
}

MAD_TEST_MAIN("RptqStoreContextTests",
	MAD_TEST(testSchemaRoundTripsThroughTheContext),
	MAD_TEST(testFaultingReturnsStableIdentities),
	MAD_TEST(testDynamicAccessorsServeDotSyntax),
	MAD_TEST(testSchemaFamilyReadsBackFromAConvertedSample),
	MAD_TEST(testDocumentPathConvertsSavesAndReopensUnchanged),
	MAD_TEST(testChangeNotificationPostsCoalescedWithCoreDataKeys),
	MAD_TEST(testSchemaFlattenedArraysAreMemoizedAndStable),
	MAD_TEST(testRptqObjectKVCSemanticsAreUnchanged),
	MAD_TEST(testBaseEntityQueryReturnsRowsOfMixedKinds),
	MAD_TEST(testSubentityInsertMintsPastSiblingKindsInTheSharedTable),
	MAD_TEST(testOwnerEntityInsertStillMintsPastItsTableMaximum),
	MAD_TEST(testHasChangesTracksInsertEditAndSave),
	MAD_TEST(testSettingTheSameValueDoesNotDirtyTheRow),
	MAD_TEST(testACleanSaveLeavesTheStoreFileUntouched),
	MAD_TEST(testOnePropertyChangeWritesOnlyThatRow),
	MAD_TEST(testAnOrderedToManyReorderIsWrittenIncrementally),
	MAD_TEST(testDeleteIsPendingUntilSave));
