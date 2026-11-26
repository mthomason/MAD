//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

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
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/MADDocumentStore.h>
#import <MAD/MADArchiveManager.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElementBarcode.h>

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

#pragma mark - Composition graph (store revision 3)

/// Builds a minimal invoices/payments composition graph -- an explicit root, two
/// named source queries over their own connections, the root's tables referencing
/// those upstream queries, and a left join -- saves it composed, releases the
/// context, reopens from disk, and recovers every fact from the reopened objects
/// alone (no fixture setup leaks into the assertions).
static void testCompositionGraphRoundTripsAndIsRevision3(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"composed.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

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

	// The root's projected fields (logical identity = the schema field name).
	RptqObject *leftKey = [context insertObjectForEntity:@"RptqQueryField" identifier:300];
	[leftKey setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[leftKey setValue:rootInvoicesTable forKey:@"inQueryTable"];
	RptqObject *rightKey = [context insertObjectForEntity:@"RptqQueryField" identifier:301];
	[rightKey setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[rightKey setValue:rootPaymentsTable forKey:@"inQueryTable"];

	// The left outer join and its keys.
	RptqObject *join = [context insertObjectForEntity:@"RptqQueryLinks" identifier:400];
	[join setValue:@1 forKey:@"type"];	// MADLinkTypeLeftOuterJoin
	[join setValue:leftKey forKey:@"hasLeftField"];
	[join setValue:rightKey forKey:@"hasRightField"];
	[join setValue:rootQuery forKey:@"inQuery"];

	[document setValue:rootQuery forKey:@"rootQuery"];

	NSError *error = nil;
	MAD_PASS([context saveComposed:&error], "composed save: %s", [[error description] UTF8String]);
	MAD_PASS(context.store.storeVersion == MADStoreMaximumReadableVersion, "the composed store is revision 3");

	// A fresh context over the same file is a real read from disk.
	RptqStoreContext *reread = openContextAtPath(directory, @"composed.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "load failed: %s", [[error description] UTF8String]);
	MAD_PASS(reread.store.storeVersion == MADStoreMaximumReadableVersion, "the reopened store is revision 3");

	RptqObject *readDocument = [reread objectForEntity:@"RptqDocument" identifier:1];
	RptqObject *readRoot = [readDocument valueForKey:@"rootQuery"];
	MAD_PASS(readRoot != nil, "the explicit root is recovered");
	MAD_PASS_EQUAL([readRoot valueForKey:@"name"], @"root", "the root is the named root query");

	RptqObject *readDatabase = [[readDocument valueForKey:@"hasDatabaseSchemas"] anyObject];
	NSSet *queries = [readDatabase valueForKey:@"hasQueries"];
	MAD_PASS(queries.count == (NSUInteger)3, "three queries survive the round trip");

	RptqObject *readInvoices = nil, *readPayments = nil;
	for (RptqObject *query in queries) {
		RptqObject *owning = [query valueForKey:@"inDatabase"];
		MAD_PASS(owning != nil, "each query keeps its connection reference");
		MAD_PASS_EQUAL([owning valueForKey:@"databaseDriverType"], @"Sqlite 3", "the connection reference is the driver type");
		if ([[query valueForKey:@"name"] isEqualToString:@"invoices"]) readInvoices = query;
		if ([[query valueForKey:@"name"] isEqualToString:@"payments"]) readPayments = query;
	}
	MAD_PASS(readInvoices != nil, "the invoices source is recovered by name");
	MAD_PASS(readPayments != nil, "the payments source is recovered by name");

	// The root's tables reference the upstream queries; the join keeps its type
	// and keys.
	NSSet *rootTables = [readRoot valueForKey:@"hasQueryTables"];
	MAD_PASS(rootTables.count == (NSUInteger)2, "the root has two upstream tables");
	NSSet *rootUpstreams = [NSSet setWithArray:[[rootTables allObjects] valueForKey:@"upstreamQuery"]];
	MAD_PASS(rootUpstreams.count == (NSUInteger)2, "both upstream queries are referenced");
	NSSet *joinSet = [readRoot valueForKey:@"hasQueryLinks"];
	MAD_PASS(joinSet.count == (NSUInteger)1, "one join survives");
	RptqObject *readJoin = joinSet.anyObject;
	MAD_PASS_EQUAL([readJoin valueForKey:@"type"], @1, "the join is a left outer join");
	RptqObject *readLeftKey = [readJoin valueForKey:@"hasLeftField"];
	RptqObject *readRightKey = [readJoin valueForKey:@"hasRightField"];
	MAD_PASS_EQUAL([[readLeftKey valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"invoice_id",
				   "the left join key is invoice_id");
	MAD_PASS_EQUAL([[readRightKey valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"invoice_id",
				   "the right join key is invoice_id");

	removeTempDirectory(directory);
}

/// An ordinary report (no composition graph) is written and reopened at the
/// ordinary revision, with the revision-2 schema -- the composition columns are
/// not added.
static void testOrdinaryReportStaysRevision2(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"ordinary.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

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
	MAD_PASS([context save:&error], "ordinary save: %s", [[error description] UTF8String]);
	MAD_PASS(context.store.storeVersion == MADStoreCurrentVersion, "the ordinary store is revision 2");

	RptqStoreContext *reread = openContextAtPath(directory, @"ordinary.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "load failed: %s", [[error description] UTF8String]);
	MAD_PASS(reread.store.storeVersion == MADStoreCurrentVersion, "the reopened ordinary store is revision 2");
	MAD_PASS([[reread objectForEntity:@"RptqDocument" identifier:1] valueForKey:@"rootQuery"] == nil,
			 "an ordinary report has no root query");

	removeTempDirectory(directory);
}

/// A composed save that fails after the migration has begun rolls the schema,
/// the version, and the rows back, leaving the previous revision-2 store intact.
static void testFailedCompositionSaveRollsBackToRevision2(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *url = [directory URLByAppendingPathComponent:@"failed.sqlite"];
	MADStore *store = [MADStore storeWithURL:url];
	MAD_PASS([store openWithError:NULL], "the store opens");

	// A composed graph (a document with an explicit root) plus a row that cannot be
	// written -- it carries an identifier value, which -writeRowForObject: refuses --
	// so the write fails after the migration columns have been added in the same
	// transaction.
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
	MAD_PASS(![store writeGraph:graph replacingAll:NO composed:YES error:&error], "the composed write fails");
	MAD_PASS(store.storeVersion == MADStoreCurrentVersion, "the failed write leaves the store at revision 2");
	[store close];

	// A fresh open sees the original revision, and the schema still has no
	// composition columns.
	MADStore *reread = [MADStore storeWithURL:url];
	MAD_PASS([reread openWithError:NULL], "the store reopens");
	MAD_PASS(reread.storeVersion == MADStoreCurrentVersion, "the on-disk revision is still 2 after the failure");
	[reread close];

	removeTempDirectory(directory);
}

/// The composition graph validator rejects a cycle and a missing upstream
/// reference, naming the affected query in each error.
static void testCompositionGraphValidation(void) {
	// A cycle: root -> invoices -> root.
	{
		NSURL *directory = makeTempDirectory();
		RptqStoreContext *context = openContextAtPath(directory, @"cycle.sqlite");
		[context loadAllWithError:NULL];
		RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
		RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
		[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
		RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
		[root setValue:@"root" forKey:@"name"];
		RptqObject *invoices = [context insertObjectForEntity:@"RptqQuery" identifier:101];
		[invoices setValue:@"invoices" forKey:@"name"];
		[database setValue:@[ root, invoices ] forKey:@"hasQueries"];
		RptqObject *rootTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
		[rootTable setValue:root forKey:@"inQuery"];
		[rootTable setValue:invoices forKey:@"upstreamQuery"];
		RptqObject *invoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:201];
		[invoicesTable setValue:invoices forKey:@"inQuery"];
		[invoicesTable setValue:root forKey:@"upstreamQuery"];
		[document setValue:root forKey:@"rootQuery"];

		RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
		NSError *error = nil;
		MAD_PASS(![model validateCompositionGraphWithError:&error], "a cycle is rejected");
		MAD_PASS(error != nil && [error.localizedDescription rangeOfString:@"root"].location != NSNotFound,
				 "the cycle error names the affected query");
		removeTempDirectory(directory);
	}

	// A missing upstream: the root's table references a query that does not exist.
	{
		NSURL *directory = makeTempDirectory();
		RptqStoreContext *context = openContextAtPath(directory, @"missing.sqlite");
		[context loadAllWithError:NULL];
		RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
		RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
		[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
		RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
		[root setValue:@"root" forKey:@"name"];
		[database setValue:@[ root ] forKey:@"hasQueries"];
		RptqObject *rootTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
		[rootTable setValue:root forKey:@"inQuery"];
		[rootTable.backingObject setReference:@999 forName:@"upstreamQuery"];
		[document setValue:root forKey:@"rootQuery"];

		RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
		NSError *error = nil;
		MAD_PASS(![model validateCompositionGraphWithError:&error], "a missing upstream is rejected");
		MAD_PASS(error != nil && [error.localizedDescription rangeOfString:@"root"].location != NSNotFound,
				 "the missing-upstream error names the affected query");
		removeTempDirectory(directory);
	}
}

#pragma mark - Archive round trip

/// Builds one source: a database with a distinct connection reference (dbname),
/// a schema table with two fields, and a named query over that table.  Returns
/// the query.
static RptqObject *MADComposedSource(RptqStoreContext *context, NSString *dbname,
									  NSString *tableName, NSString *queryName,
									  int64_t databaseId, int64_t queryId, int64_t tableId) {
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:databaseId];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	RptqObject *credential = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];
	[credential setValue:dbname forKey:@"dbname"];
	[database setValue:credential forKey:@"ownedByUser"];

	RptqObject *table = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:tableId + 1];
	[table setValue:tableName forKey:@"name"];
	RptqObject *idField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:tableId + 2];
	[idField setValue:@"invoice_id" forKey:@"name"];
	RptqObject *amountField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:tableId + 3];
	[amountField setValue:@"amount" forKey:@"name"];
	[database setValue:@[ table ] forKey:@"hasTables"];
	[table setValue:@[ idField, amountField ] forKey:@"hasFields"];

	RptqObject *query = [context insertObjectForEntity:@"RptqQuery" identifier:queryId];
	[query setValue:queryName forKey:@"name"];
	[database setValue:@[ query ] forKey:@"hasQueries"];
	RptqObject *queryTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:tableId];
	[queryTable setValue:table forKey:@"databaseSchemaTable"];
	[queryTable setValue:query forKey:@"inQuery"];
	return query;
}

/// A composed document saved through the production writer is copied as one .mad
/// file to a clean directory and reopened through the production reader, which
/// recovers both connection references, the root, the join and its field
/// ownership, and the ordered output projection.
static void testComposedArchiveRoundTrip(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *madURL = [directory URLByAppendingPathComponent:@"composed.mad"];

	// Build and save the composed document through the store + archive writers.
	MADDocumentStore *documentStore = [MADDocumentStore storeForDocumentURL: madURL];
	NSError *error = nil;
	MAD_PASS([documentStore openWithError:&error], "the document store opens: %s", [[error description] UTF8String]);
	RptqStoreContext *context = documentStore.context;
	MAD_PASS([context loadAllWithError:&error], "the context loads: %s", [[error description] UTF8String]);

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *invoices = MADComposedSource(context, @"invoices.sqlite", @"invoices", @"invoices", 10, 101, 200);
	RptqObject *payments = MADComposedSource(context, @"payments.sqlite", @"payments", @"payments", 20, 102, 300);
	[document setValue:@[ [invoices valueForKey:@"inDatabase"], [payments valueForKey:@"inDatabase"] ] forKey:@"hasDatabaseSchemas"];

	RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[root setValue:@"root" forKey:@"name"];
	[root setValue:[invoices valueForKey:@"inDatabase"] forKey:@"inDatabase"];

	RptqObject *rootInvoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:400];
	[rootInvoicesTable setValue:root forKey:@"inQuery"];
	[rootInvoicesTable setValue:invoices forKey:@"upstreamQuery"];
	RptqObject *rootPaymentsTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:401];
	[rootPaymentsTable setValue:root forKey:@"inQuery"];
	[rootPaymentsTable setValue:payments forKey:@"upstreamQuery"];

	// The root's ordered outputs, with an explicit non-incidental order.
	// invoice_id and amount are 202/203 on invoices; amount is 303 on payments.
	RptqObject *invoiceIdField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:202];
	RptqObject *invoiceAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:203];
	RptqObject *paymentAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:303];

	RptqObject *out0 = [context insertObjectForEntity:@"RptqQueryField" identifier:500];
	[out0 setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[out0 setValue:rootInvoicesTable forKey:@"inQueryTable"];
	[out0 setValue:@"invoice_id" forKey:@"outputKey"];
	[out0 setValue:@0 forKey:@"outputIndex"];
	RptqObject *out1 = [context insertObjectForEntity:@"RptqQueryField" identifier:501];
	[out1 setValue:invoiceAmountField forKey:@"databaseSchemaField"];
	[out1 setValue:rootInvoicesTable forKey:@"inQueryTable"];
	[out1 setValue:@"invoice_amount" forKey:@"outputKey"];
	[out1 setValue:@1 forKey:@"outputIndex"];
	RptqObject *out2 = [context insertObjectForEntity:@"RptqQueryField" identifier:502];
	[out2 setValue:paymentAmountField forKey:@"databaseSchemaField"];
	[out2 setValue:rootPaymentsTable forKey:@"inQueryTable"];
	[out2 setValue:@"payment_amount" forKey:@"outputKey"];
	[out2 setValue:@2 forKey:@"outputIndex"];

	[document setValue:root forKey:@"rootQuery"];

	MAD_PASS([context saveComposed:&error], "composed save: %s", [[error description] UTF8String]);
	[documentStore close];

	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: documentStore.gutsURL archiveURL: madURL];
	writer.composed = YES;
	MAD_PASS([writer archive:YES], "the composed archive writes");

	// Copy only the .mad into a clean directory and reopen it there.
	NSURL *cleanDirectory = makeTempDirectory();
	NSURL *copyURL = [cleanDirectory URLByAppendingPathComponent:@"copy.mad"];
	MAD_PASS([[NSFileManager defaultManager] copyItemAtURL: madURL toURL: copyURL error: &error],
			 "the .mad copies alone: %s", [[error description] UTF8String]);

	MADDocumentStore *reopenedStore = [MADDocumentStore storeForDocumentURL: copyURL];
	MADArchiveManager *reader = [[MADArchiveManager alloc] initWithFileWrapperURL: reopenedStore.gutsURL archiveURL: copyURL];
	MAD_PASS([reader unarchiveWithError: &error], "the copy unarchives: %s", [[error description] UTF8String]);
	MAD_PASS([reopenedStore openWithError: &error], "the copy opens: %s", [[error description] UTF8String]);
	RptqStoreContext *reread = reopenedStore.context;
	MAD_PASS([reread loadAllWithError: &error], "the copy loads: %s", [[error description] UTF8String]);

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: reread];
	RptqQuery *readRoot = model.rootQuery;
	MAD_PASS(readRoot != nil, "the root is recovered");
	MAD_PASS_EQUAL([readRoot valueForKey:@"name"], @"root", "the root is the named root");

	// Both distinct connection references survive.
	NSSet *databases = [model valueForKey:@"hasDatabaseSchemas"];
	MAD_PASS(databases.count == (NSUInteger)2, "two distinct connections survive");
	NSMutableSet *dbnames = [NSMutableSet set];
	for (RptqObject *db in databases) {
		[dbnames addObject:[[db valueForKey:@"ownedByUser"] valueForKey:@"dbname"]];
	}
	MAD_PASS([dbnames containsObject:@"invoices.sqlite"], "the invoices connection reference survives");
	MAD_PASS([dbnames containsObject:@"payments.sqlite"], "the payments connection reference survives");

	// The ordered output projection, recovered from the document alone.
	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:&error];
	MAD_PASS(outputs != nil, "the output order is recovered: %s", [[error description] UTF8String]);
	MAD_PASS(outputs.count == (NSUInteger)3, "three outputs are recovered");
	if (outputs.count == 3) {
		RptqQueryField *o0 = outputs[0], *o1 = outputs[1], *o2 = outputs[2];
		MAD_PASS_EQUAL(o0.outputKey, @"invoice_id", "output 0 is invoice_id");
		MAD_PASS_EQUAL([o0 valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"invoices", "output 0 comes from invoices");
		MAD_PASS_EQUAL(o1.outputKey, @"invoice_amount", "output 1 is invoice_amount");
		MAD_PASS_EQUAL([o1 valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"invoices", "output 1 comes from invoices");
		MAD_PASS_EQUAL(o2.outputKey, @"payment_amount", "output 2 is payment_amount");
		MAD_PASS_EQUAL([o2 valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"payments", "output 2 comes from payments");
	}

	removeTempDirectory(directory);
	removeTempDirectory(cleanDirectory);
}

#pragma mark - Reorder, Save As, and failed save

/// Builds a composed invoices/payments graph on `context`, with the root output
/// order either `invoice_id, invoice_amount, payment_amount` or the reorder
/// `invoice_id, payment_amount, invoice_amount`.
static RptqStoreContext *MADBuildComposedGraph(RptqStoreContext *context, BOOL reordered) {
	[context loadAllWithError:NULL];
	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *invoices = MADComposedSource(context, @"invoices.sqlite", @"invoices", @"invoices", 10, 101, 200);
	RptqObject *payments = MADComposedSource(context, @"payments.sqlite", @"payments", @"payments", 20, 102, 300);
	[document setValue:@[ [invoices valueForKey:@"inDatabase"], [payments valueForKey:@"inDatabase"] ] forKey:@"hasDatabaseSchemas"];
	RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[root setValue:@"root" forKey:@"name"];
	[root setValue:[invoices valueForKey:@"inDatabase"] forKey:@"inDatabase"];
	RptqObject *rootInvoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:400];
	[rootInvoicesTable setValue:root forKey:@"inQuery"];
	[rootInvoicesTable setValue:invoices forKey:@"upstreamQuery"];
	RptqObject *rootPaymentsTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:401];
	[rootPaymentsTable setValue:root forKey:@"inQuery"];
	[rootPaymentsTable setValue:payments forKey:@"upstreamQuery"];

	RptqObject *invoiceIdField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:202];
	RptqObject *invoiceAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:203];
	RptqObject *paymentAmountField = [context objectForEntity:@"RptqDatabaseSchemaField" identifier:303];

	RptqObject *out0 = [context insertObjectForEntity:@"RptqQueryField" identifier:500];
	[out0 setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[out0 setValue:rootInvoicesTable forKey:@"inQueryTable"];
	[out0 setValue:@"invoice_id" forKey:@"outputKey"];
	[out0 setValue:@0 forKey:@"outputIndex"];

	RptqObject *mid = [context insertObjectForEntity:@"RptqQueryField" identifier:501];
	RptqObject *last = [context insertObjectForEntity:@"RptqQueryField" identifier:502];
	if (reordered) {
		[mid setValue:paymentAmountField forKey:@"databaseSchemaField"];
		[mid setValue:rootPaymentsTable forKey:@"inQueryTable"];
		[mid setValue:@"payment_amount" forKey:@"outputKey"];
		[mid setValue:@1 forKey:@"outputIndex"];
		[last setValue:invoiceAmountField forKey:@"databaseSchemaField"];
		[last setValue:rootInvoicesTable forKey:@"inQueryTable"];
		[last setValue:@"invoice_amount" forKey:@"outputKey"];
		[last setValue:@2 forKey:@"outputIndex"];
	} else {
		[mid setValue:invoiceAmountField forKey:@"databaseSchemaField"];
		[mid setValue:rootInvoicesTable forKey:@"inQueryTable"];
		[mid setValue:@"invoice_amount" forKey:@"outputKey"];
		[mid setValue:@1 forKey:@"outputIndex"];
		[last setValue:paymentAmountField forKey:@"databaseSchemaField"];
		[last setValue:rootPaymentsTable forKey:@"inQueryTable"];
		[last setValue:@"payment_amount" forKey:@"outputKey"];
		[last setValue:@2 forKey:@"outputIndex"];
	}
	[document setValue:root forKey:@"rootQuery"];
	return context;
}

/// The reordered projection — payment_amount between the two invoice outputs —
/// survives a store round trip with the exact sequence and source fields.
static void testComposedProjectionReorder(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"reorder.sqlite");
	MADBuildComposedGraph(context, YES);
	NSError *error = nil;
	MAD_PASS([context saveComposed:&error], "composed save: %s", [[error description] UTF8String]);

	RptqStoreContext *reread = openContextAtPath(directory, @"reorder.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "load: %s", [[error description] UTF8String]);
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: reread];
	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:&error];
	MAD_PASS(outputs.count == (NSUInteger)3, "three outputs");
	if (outputs.count == 3) {
		MAD_PASS_EQUAL(outputs[0].outputKey, @"invoice_id", "output 0 is invoice_id");
		MAD_PASS_EQUAL([outputs[0] valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"invoices", "output 0 from invoices");
		MAD_PASS_EQUAL(outputs[1].outputKey, @"payment_amount", "output 1 is payment_amount (between the invoices)");
		MAD_PASS_EQUAL([outputs[1] valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"payments", "output 1 from payments");
		MAD_PASS_EQUAL(outputs[2].outputKey, @"invoice_amount", "output 2 is invoice_amount");
		MAD_PASS_EQUAL([outputs[2] valueForKeyPath:@"inQueryTable.upstreamQuery.name"], @"invoices", "output 2 from invoices");
	}
	removeTempDirectory(directory);
}

/// Save As: the original keeps its order and the copy keeps its reordered
/// projection, in different directories under the same basename.
static void testComposedSaveAs(void) {
	NSURL *dirA = makeTempDirectory();
	NSURL *dirB = makeTempDirectory();
	NSURL *urlA = [dirA URLByAppendingPathComponent:@"Shared.mad"];
	NSURL *urlB = [dirB URLByAppendingPathComponent:@"Shared.mad"];
	NSError *error = nil;

	MADDocumentStore *storeA = [MADDocumentStore storeForDocumentURL: urlA];
	MAD_PASS([storeA openWithError:&error], "A opens");
	MADBuildComposedGraph(storeA.context, NO);
	MAD_PASS([storeA.context saveComposed:&error], "A saves: %s", [[error description] UTF8String]);
	[storeA close];
	MADArchiveManager *wa = [[MADArchiveManager alloc] initWithFileWrapperURL: storeA.gutsURL archiveURL: urlA];
	wa.composed = YES;
	MAD_PASS([wa archive:YES], "A archives");

	MADDocumentStore *storeB = [MADDocumentStore storeForDocumentURL: urlB];
	MAD_PASS([storeB openWithError:&error], "B opens");
	MADBuildComposedGraph(storeB.context, YES);
	MAD_PASS([storeB.context saveComposed:&error], "B saves: %s", [[error description] UTF8String]);
	[storeB close];
	MADArchiveManager *wb = [[MADArchiveManager alloc] initWithFileWrapperURL: storeB.gutsURL archiveURL: urlB];
	wb.composed = YES;
	MAD_PASS([wb archive:YES], "B archives");

	// Reopen A: original order.
	MADDocumentStore *reopenA = [MADDocumentStore storeForDocumentURL: urlA];
	MAD_PASS([[[MADArchiveManager alloc] initWithFileWrapperURL: reopenA.gutsURL archiveURL: urlA] unarchiveWithError:&error], "A reopens");
	MAD_PASS([reopenA openWithError:&error], "A store opens");
	RptqDocument *modelA = [RptqDocument newDocumentReadFromManagedObjectContext: reopenA.context];
	NSArray<RptqQueryField *> *a = [modelA orderedCompositionOutputsWithError:&error];
	MAD_PASS(a.count == 3 && [a[1].outputKey isEqualToString:@"invoice_amount"], "A keeps its original order");
	MAD_PASS([[modelA valueForKey:@"hasDatabaseSchemas"] count] == (NSUInteger)2, "A keeps its two connections");

	// Reopen B: reordered.
	MADDocumentStore *reopenB = [MADDocumentStore storeForDocumentURL: urlB];
	MAD_PASS([[[MADArchiveManager alloc] initWithFileWrapperURL: reopenB.gutsURL archiveURL: urlB] unarchiveWithError:&error], "B reopens");
	MAD_PASS([reopenB openWithError:&error], "B store opens");
	RptqDocument *modelB = [RptqDocument newDocumentReadFromManagedObjectContext: reopenB.context];
	NSArray<RptqQueryField *> *b = [modelB orderedCompositionOutputsWithError:&error];
	MAD_PASS(b.count == 3 && [b[1].outputKey isEqualToString:@"payment_amount"], "B keeps its reordered projection");

	removeTempDirectory(dirA);
	removeTempDirectory(dirB);
}

/// A failed archive save leaves the previous destination intact.
static void testComposedFailedArchivePreservesDestination(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *madURL = [directory URLByAppendingPathComponent:@"report.mad"];
	NSError *error = nil;

	// Save A (default order).
	MADDocumentStore *store = [MADDocumentStore storeForDocumentURL: madURL];
	MAD_PASS([store openWithError:&error], "the store opens");
	MADBuildComposedGraph(store.context, NO);
	MAD_PASS([store.context saveComposed:&error], "A saves");
	[store close];
	MADArchiveManager *wa = [[MADArchiveManager alloc] initWithFileWrapperURL: store.gutsURL archiveURL: madURL];
	wa.composed = YES;
	MAD_PASS([wa archive:YES], "A archives");

	// Prepare a visibly different B: reorder the projection in the guts.
	[store openWithError:&error];
	RptqStoreContext *context = store.context;
	[context loadAllWithError:NULL];
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:NULL];
	// Swap output 1 and 2's indices so payment_amount moves between the invoices.
	[outputs[1] setValue:@2 forKey:@"outputIndex"];
	[outputs[2] setValue:@1 forKey:@"outputIndex"];
	[context markObjectChanged:outputs[1]];
	[context markObjectChanged:outputs[2]];
	MAD_PASS([context saveComposed:&error], "B saves in the store");
	[store close];

	// Force the archive to fail: move the guts aside so the requirements record
	// cannot be written, aborting the save before it touches the destination.
	NSString *movedGuts = [store.gutsURL.path stringByAppendingString:@".moved"];
	[[NSFileManager defaultManager] moveItemAtPath:store.gutsURL.path toPath:movedGuts error:NULL];
	MADArchiveManager *failing = [[MADArchiveManager alloc] initWithFileWrapperURL: store.gutsURL archiveURL: madURL];
	failing.composed = YES;
	MAD_PASS(![failing archive:YES], "the archive fails");

	// A still opens with its original order.
	MADDocumentStore *reopen = [MADDocumentStore storeForDocumentURL: madURL];
	MAD_PASS([[[MADArchiveManager alloc] initWithFileWrapperURL: reopen.gutsURL archiveURL: madURL] unarchiveWithError:&error], "the destination still unpacks");
	MAD_PASS([reopen openWithError:&error], "the destination still opens");
	RptqDocument *reopenedModel = [RptqDocument newDocumentReadFromManagedObjectContext: reopen.context];
	NSArray<RptqQueryField *> *a = [reopenedModel orderedCompositionOutputsWithError:&error];
	MAD_PASS(a.count == 3 && [a[1].outputKey isEqualToString:@"invoice_amount"], "the destination keeps its previous projection");

	removeTempDirectory(directory);
}

#pragma mark - Importing a query graph

/// Builds an ordinary single-query graph -- one database, its credential, one schema
/// table and field, and one query with a query table and field -- using fixed
/// identifiers so two independent documents collide exactly.
static void buildStandardQueryGraphInContext(RptqStoreContext *context,
											 NSString *tableName,
											 NSString *fieldName,
											 NSString *host) {
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

static void testImportQueryGraphRemapsIdentifiersAndResolvesRelativePath(void) {
	NSURL *directory = makeTempDirectory();

	RptqStoreContext *source = openContextAtPath(directory, @"source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");
	buildStandardQueryGraphInContext(source, @"invoices", @"amount", @"invoices.sqlite");
	MAD_PASS([source save:NULL], "the source saves");

	RptqStoreContext *destination = openContextAtPath(directory, @"destination.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	buildStandardQueryGraphInContext(destination, @"orders", @"total", @"orders.sqlite");
	MAD_PASS([destination save:NULL], "the destination saves");

	NSURL *childURL = [directory URLByAppendingPathComponent:@"child.mad"];
	RptqQuery *importedRoot = [destination importQueryGraphFromContext:source relativePathBaseURL:childURL error:NULL];
	MAD_PASS(importedRoot != nil, "the import returns the imported root");
	MAD_PASS(importedRoot.identifier != (int64_t)100, "the imported query is remapped");

	MAD_PASS([destination objectsForEntity:@"RptqQuery"].count == (NSUInteger)2, "two queries coexist");
	MAD_PASS([destination objectsForEntity:@"RptqDatabase"].count == (NSUInteger)2, "two databases coexist");
	RptqObject *destinationDocumentRow = [destination objectForEntity:@"RptqDocument" identifier:1];
	MAD_PASS([[destinationDocumentRow valueForKey:@"hasDatabaseSchemas"] count] == (NSUInteger)2, "the imported database joins the document");
	MAD_PASS([destination objectsForEntity:@"RptqDatabaseSchemaTable"].count == (NSUInteger)2, "two schema tables coexist");
	MAD_PASS([destination objectsForEntity:@"RptqDatabaseSchemaField"].count == (NSUInteger)2, "two schema fields coexist");
	MAD_PASS([destination objectsForEntity:@"RptqQueryTable"].count == (NSUInteger)2, "two query tables coexist");
	MAD_PASS([destination objectsForEntity:@"RptqQueryField"].count == (NSUInteger)2, "two query fields coexist");

	RptqObject *importedDatabase = [importedRoot valueForKey:@"inDatabase"];
	MAD_PASS(importedDatabase.identifier != (int64_t)10, "the imported database is remapped");
	RptqObject *importedTable = [[importedDatabase valueForKey:@"hasTables"] anyObject];
	MAD_PASS_EQUAL([importedTable valueForKey:@"name"], @"invoices", "the imported schema table keeps its name");
	RptqObject *importedField = [[importedTable valueForKey:@"hasFields"] firstObject];
	MAD_PASS_EQUAL([importedField valueForKey:@"name"], @"amount", "the imported schema field keeps its name");

	RptqObject *importedQueryTable = [[importedRoot valueForKey:@"hasQueryTables"] anyObject];
	MAD_PASS(importedQueryTable != nil, "the imported query owns a query table");
	RptqObject *importedQueryField = [[importedQueryTable valueForKey:@"hasQueryFields"] anyObject];
	MAD_PASS(importedQueryField != nil, "the imported query table owns a query field");
	MAD_PASS_EQUAL([[importedQueryField valueForKey:@"databaseSchemaField"] valueForKey:@"name"], @"amount", "the query field binds to the imported schema field");

	RptqObject *importedCredential = [importedDatabase valueForKey:@"ownedByUser"];
	MAD_PASS_EQUAL([importedCredential valueForKey:@"host"],
				   [[childURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"invoices.sqlite"].path,
				   "the relative SQLite path resolves against the child location");

	RptqObject *sourceQuery = [source objectForEntity:@"RptqQuery" identifier:100];
	MAD_PASS(sourceQuery != nil, "the source query is untouched");
	RptqObject *sourceTable = [[[sourceQuery valueForKey:@"inDatabase"] valueForKey:@"hasTables"] anyObject];
	MAD_PASS_EQUAL([sourceTable valueForKey:@"name"], @"invoices", "the source schema is intact");

	removeTempDirectory(directory);
}

static void testImportComposedGraphBringsRootAndLeaves(void) {
	NSURL *directory = makeTempDirectory();

	RptqStoreContext *source = openContextAtPath(directory, @"composed-source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");

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
	MAD_PASS([source saveComposed:NULL], "the composed source saves");

	RptqStoreContext *destination = openContextAtPath(directory, @"composed-destination.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	RptqObject *destinationDocument = [destination insertObjectForEntity:@"RptqDocument" identifier:1];

	RptqQuery *importedRoot = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:NULL];
	MAD_PASS(importedRoot != nil, "the import returns the composed root");
	MAD_PASS_EQUAL([importedRoot valueForKey:@"name"], @"root", "the imported root keeps its name");

	MAD_PASS([destination objectsForEntity:@"RptqQuery"].count == (NSUInteger)3, "root plus two leaves come along");
	MAD_PASS([destination objectsForEntity:@"RptqDatabaseSchemaTable"].count == (NSUInteger)2, "both schema tables come along");

	NSSet *importedRootTables = [importedRoot valueForKey:@"hasQueryTables"];
	MAD_PASS(importedRootTables.count == (NSUInteger)2, "the imported root keeps its two upstream tables");
	NSMutableSet *upstreamNames = [NSMutableSet set];
	for (RptqObject *table in importedRootTables) {
		RptqObject *upstream = [table valueForKey:@"upstreamQuery"];
		MAD_PASS(upstream != nil, "each upstream table names its source");
		[upstreamNames addObject:[upstream valueForKey:@"name"]];
	}
	NSSet *expectedUpstreams = [NSSet setWithArray:@[ @"invoices", @"payments" ]];
	MAD_PASS([upstreamNames isEqualToSet:expectedUpstreams], "the imported root references both leaves");

	MAD_PASS([destinationDocument valueForKey:@"rootQuery"] == nil,
			 "the source document's root relationship is not copied");

	removeTempDirectory(directory);
}

/// Each node owns its five structural sections via `ownerQuery`; a save/reopen keeps
/// three independent layouts -- and a data-field element on a leaf -- intact.
static void testPerNodeLayoutRoundTripsWithThreeLayouts(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"per-node-layout.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];

	RptqQuery *root = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:100];
	root.name = @"root";
	RptqQuery *leaf1 = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:101];
	leaf1.name = @"leaf1";
	RptqQuery *leaf2 = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:102];
	leaf2.name = @"leaf2";
	[database setValue:@[ root, leaf1, leaf2 ] forKey:@"hasQueries"];
	[document setValue:root forKey:@"rootQuery"];

	RptqDocumentSection *reportHeader = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:1];
	reportHeader.type = MADDocumentSectionTypeReportHeader;
	reportHeader.visibility = YES;
	RptqDocumentSection *reportFooter = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:2];
	reportFooter.type = MADDocumentSectionTypeReportFooter;
	reportFooter.visibility = YES;
	RptqDocumentSection *pageHeader = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:3];
	pageHeader.type = MADDocumentSectionTypePageHeader;
	pageHeader.visibility = YES;
	RptqDocumentSection *pageFooter = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:4];
	pageFooter.type = MADDocumentSectionTypePageFooter;
	pageFooter.visibility = YES;
	RptqDocumentSection *detail = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:5];
	detail.type = MADDocumentSectionTypeBody;
	detail.visibility = YES;
	[document setValue:reportHeader forKey:@"hasReportHeaderSection"];
	[document setValue:reportFooter forKey:@"hasReportFooterSection"];
	[document setValue:pageHeader forKey:@"hasPageHeaderSection"];
	[document setValue:pageFooter forKey:@"hasPageFooterSection"];
	[document setValue:detail forKey:@"hasDetailSection"];

	[RptqDocumentSection createStructuralSectionsForQuery:leaf1 managedObjectContext:context];
	[RptqDocumentSection createStructuralSectionsForQuery:leaf2 managedObjectContext:context];

	// A leaf1 query field and a data-field element bound to it.
	RptqObject *schemaTable = [context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[schemaTable setValue:@"invoices" forKey:@"name"];
	RptqObject *schemaField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[schemaField setValue:@"amount" forKey:@"name"];
	[database setValue:@[ schemaTable ] forKey:@"hasTables"];
	[schemaTable setValue:@[ schemaField ] forKey:@"hasFields"];
	RptqObject *leaf1Table = [context insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[leaf1Table setValue:leaf1 forKey:@"inQuery"];
	[leaf1Table setValue:schemaTable forKey:@"databaseSchemaTable"];
	RptqQueryField *leaf1Field = (RptqQueryField *)[context insertObjectForEntity:@"RptqQueryField" identifier:300];
	[leaf1Field setValue:schemaField forKey:@"databaseSchemaField"];
	[leaf1Field setValue:leaf1Table forKey:@"inQueryTable"];
	[leaf1Table setValue:@[ leaf1Field ] forKey:@"hasQueryFields"];

	RptqDocumentSection *leaf1Detail = nil;
	for (RptqDocumentSection *section in leaf1.hasLayoutSections) {
		if (section.type == MADDocumentSectionTypeBody) leaf1Detail = section;
	}
	MAD_PASS(leaf1Detail != nil, "leaf1 has a detail section");
	RptqDocumentSectionRows *leaf1Row = leaf1Detail.hasRows.firstObject;
	MAD_PASS(leaf1Row != nil, "leaf1's detail section has a row");
	RptqDocumentElementLabelDataField *leaf1DataField =
		(RptqDocumentElementLabelDataField *)[context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	leaf1DataField.referencesQueryField = leaf1Field;
	leaf1DataField.fieldID = @"amount";
	leaf1DataField.inSectionRow = leaf1Row;

	MAD_PASS([context saveComposed:NULL], "the composed store saves");
	MAD_PASS(context.store.storeVersion == MADStoreMaximumReadableVersion, "the composed save is revision 4");

	RptqStoreContext *reread = openContextAtPath(directory, @"per-node-layout.sqlite");
	MAD_PASS([reread loadAllWithError:NULL], "the store reopens");
	RptqDocument *readDocument = [RptqDocument newDocumentReadFromManagedObjectContext:reread];
	RptqQuery *readRoot = readDocument.rootQuery;
	MAD_PASS_EQUAL(readRoot.name, @"root", "the root reads back");

	NSArray<RptqDocumentSection *> *rootSections = [readRoot orderedLayoutSectionsForDocument:readDocument];
	MAD_PASS(rootSections.count == (NSUInteger)5, "the root's ordered layout is the document's five sections");

	RptqQuery *readLeaf1 = nil;
	for (RptqQuery *query in readRoot.inDatabase.hasQueries) {
		if (query == readRoot) continue;
		MAD_PASS(query.hasLayoutSections.count == (NSUInteger)5, "each leaf owns five sections");
		for (RptqDocumentSection *section in query.hasLayoutSections) {
			MAD_PASS_EQUAL(section.ownerQuery.name, query.name, "each section is owned by its query");
		}
		if ([query.name isEqualToString:@"leaf1"]) readLeaf1 = query;
	}
	MAD_PASS(readLeaf1 != nil, "leaf1 reads back");

	RptqDocumentSection *readLeaf1Detail = nil;
	for (RptqDocumentSection *section in readLeaf1.hasLayoutSections) {
		if (section.type == MADDocumentSectionTypeBody) readLeaf1Detail = section;
	}
	MAD_PASS(readLeaf1Detail.hasRows.firstObject.hasObjects.count == (NSUInteger)1, "leaf1's data-field element survives");
	RptqDocumentElementLabelDataField *readElement =
		(RptqDocumentElementLabelDataField *)readLeaf1Detail.hasRows.firstObject.hasObjects.firstObject;
	MAD_PASS_EQUAL(readElement.fieldID, @"amount", "the element keeps its field id");
	MAD_PASS(readElement.referencesQueryField != nil, "the element keeps its field binding");
	MAD_PASS_EQUAL(readElement.referencesQueryField.databaseSchemaField.name, @"amount", "the element binds to the leaf's own field");

	removeTempDirectory(directory);
}

/// A layoutless source (a query with no sections of its own) imports with five empty
/// sections, so the imported child is authorable immediately.
static void testImportLayoutlessSourceYieldsEmptySections(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *source = openContextAtPath(directory, @"layoutless-source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");
	buildStandardQueryGraphInContext(source, @"t", @"f", @"/tmp/t.sqlite");

	RptqStoreContext *destination = openContextAtPath(directory, @"layoutless-dest.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	[destination insertObjectForEntity:@"RptqDocument" identifier:1];

	RptqQuery *imported = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:NULL];
	MAD_PASS(imported != nil, "the import returns a root");
	MAD_PASS(imported.hasLayoutSections.count == (NSUInteger)5, "the layoutless source imports five sections");

	removeTempDirectory(directory);
}

/// A source with a designed layout imports its five sections onto the imported query.
static void testImportCopiesSourceLayout(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *source = openContextAtPath(directory, @"layout-source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");
	buildStandardQueryGraphInContext(source, @"t", @"f", @"/tmp/t.sqlite");

	RptqObject *sourceDocument = [source objectForEntity:@"RptqDocument" identifier:1];
	for (int i = 1; i <= 5; i++) {
		RptqObject *section = [source insertObjectForEntity:@"RptqDocumentSection" identifier:i];
		[section setValue:@(i) forKey:@"type"];
		[section setValue:@YES forKey:@"visibility"];
	}
	[sourceDocument setValue:[source objectForEntity:@"RptqDocumentSection" identifier:1] forKey:@"hasReportHeaderSection"];
	[sourceDocument setValue:[source objectForEntity:@"RptqDocumentSection" identifier:2] forKey:@"hasReportFooterSection"];
	[sourceDocument setValue:[source objectForEntity:@"RptqDocumentSection" identifier:3] forKey:@"hasPageHeaderSection"];
	[sourceDocument setValue:[source objectForEntity:@"RptqDocumentSection" identifier:4] forKey:@"hasPageFooterSection"];
	[sourceDocument setValue:[source objectForEntity:@"RptqDocumentSection" identifier:5] forKey:@"hasDetailSection"];

	RptqStoreContext *destination = openContextAtPath(directory, @"layout-dest.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	[destination insertObjectForEntity:@"RptqDocument" identifier:1];

	RptqQuery *imported = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:NULL];
	MAD_PASS(imported != nil, "the import returns a root");
	MAD_PASS(imported.hasLayoutSections.count == (NSUInteger)5, "the source's five sections import");
	for (RptqDocumentSection *section in imported.hasLayoutSections) {
		MAD_PASS_EQUAL(section.ownerQuery.name, imported.name, "each section is owned by the imported query");
	}

	removeTempDirectory(directory);
}

/// A designed layout imports its elements with every field reference remapped to the
/// imported query's field (data-field, aggregate, and barcode each carry one).
static void testImportLayoutWithElementsRemapsFieldRefs(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *source = openContextAtPath(directory, @"layout-elements-source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");
	buildStandardQueryGraphInContext(source, @"invoices", @"amount", @"/tmp/invoices.sqlite");

	RptqObject *sourceDocument = [source objectForEntity:@"RptqDocument" identifier:1];
	RptqDocumentSection *detail = (RptqDocumentSection *)[source insertObjectForEntity:@"RptqDocumentSection" identifier:1];
	detail.type = MADDocumentSectionTypeBody;
	detail.visibility = YES;
	RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[source insertObjectForEntity:@"RptqDocumentSectionRows" identifier:0];
	row.inSection = detail;
	detail.hasRows = [[NSOrderedSet alloc] initWithObject:row];
	[sourceDocument setValue:detail forKey:@"hasDetailSection"];

	RptqQueryField *sourceField = (RptqQueryField *)[source objectForEntity:@"RptqQueryField" identifier:300];

	RptqDocumentElementLabelDataField *dataField =
		(RptqDocumentElementLabelDataField *)[source insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	dataField.referencesQueryField = sourceField;
	dataField.fieldID = @"amount";
	dataField.inSectionRow = row;

	RptqDocumentElementAggregate *aggregate =
		(RptqDocumentElementAggregate *)[source insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];
	aggregate.aggregateField = sourceField;
	aggregate.inSectionRow = row;

	RptqDocumentElementBarcode *barcode =
		(RptqDocumentElementBarcode *)[source insertObjectForEntity:@"RptqDocumentElementBarcode" identifier:0];
	barcode.referencesField1 = sourceField;
	barcode.inSectionRow = row;

	MAD_PASS([source save:NULL], "the source saves");

	RptqStoreContext *destination = openContextAtPath(directory, @"layout-elements-dest.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	[destination insertObjectForEntity:@"RptqDocument" identifier:1];

	RptqQuery *imported = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:NULL];
	MAD_PASS(imported != nil, "the import returns a root");

	RptqDocumentSection *importedDetail = nil;
	for (RptqDocumentSection *section in imported.hasLayoutSections) {
		if (section.type == MADDocumentSectionTypeBody) importedDetail = section;
	}
	MAD_PASS(importedDetail != nil, "the imported detail section is present");
	MAD_PASS(importedDetail.hasRows.firstObject.hasObjects.count == (NSUInteger)3, "the three elements import");

	RptqQueryField *importedField = nil;
	for (RptqQueryTable *table in imported.hasQueryTables) {
		importedField = table.hasQueryFields.anyObject;
	}
	MAD_PASS(importedField != nil, "the imported query owns its field");
	MAD_PASS(importedField.identifier != sourceField.identifier, "the imported field is remapped");
	MAD_PASS_EQUAL(importedField.databaseSchemaField.name, @"amount", "the imported field keeps its name");

	NSUInteger seen = 0;
	for (RptqDocumentElement *element in importedDetail.hasRows.firstObject.hasObjects) {
		if ([element isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
			RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)element;
			MAD_PASS_EQUAL(df.referencesQueryField, importedField, "the data field rebinds to the imported field");
			MAD_PASS_EQUAL(df.fieldID, @"amount", "the data field keeps its field id");
			seen++;
		} else if ([element isKindOfClass:[RptqDocumentElementAggregate class]]) {
			MAD_PASS_EQUAL([(RptqDocumentElementAggregate *)element aggregateField], importedField, "the aggregate rebinds to the imported field");
			seen++;
		} else if ([element isKindOfClass:[RptqDocumentElementBarcode class]]) {
			MAD_PASS_EQUAL([(RptqDocumentElementBarcode *)element referencesField1], importedField, "the barcode rebinds to the imported field");
			seen++;
		}
	}
	MAD_PASS(seen == (NSUInteger)3, "all three element kinds are present");

	removeTempDirectory(directory);
}

/// A nested four-node graph (root → intermediate composer → two leaves) imports with
/// every node's layout and its composing/leaf identity intact.
static void testImportNestedFourNodeGraph(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *source = openContextAtPath(directory, @"nested-source.sqlite");
	MAD_PASS([source loadAllWithError:NULL], "the source loads");

	RptqObject *document = [source insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [source insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];

	RptqObject *invoicesTable = [source insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:11];
	[invoicesTable setValue:@"invoices" forKey:@"name"];
	RptqObject *paymentsTable = [source insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:12];
	[paymentsTable setValue:@"payments" forKey:@"name"];
	RptqObject *invoiceIdField = [source insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[invoiceIdField setValue:@"invoice_id" forKey:@"name"];
	RptqObject *amountField = [source insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[amountField setValue:@"amount" forKey:@"name"];
	[database setValue:@[ invoicesTable, paymentsTable ] forKey:@"hasTables"];
	[invoicesTable setValue:@[ invoiceIdField, amountField ] forKey:@"hasFields"];
	[paymentsTable setValue:@[ invoiceIdField, amountField ] forKey:@"hasFields"];

	RptqQuery *root = (RptqQuery *)[source insertObjectForEntity:@"RptqQuery" identifier:100];
	[root setValue:@"root" forKey:@"name"];
	RptqQuery *mid = (RptqQuery *)[source insertObjectForEntity:@"RptqQuery" identifier:101];
	[mid setValue:@"mid" forKey:@"name"];
	RptqQuery *invoices = (RptqQuery *)[source insertObjectForEntity:@"RptqQuery" identifier:102];
	[invoices setValue:@"invoices" forKey:@"name"];
	RptqQuery *payments = (RptqQuery *)[source insertObjectForEntity:@"RptqQuery" identifier:103];
	[payments setValue:@"payments" forKey:@"name"];
	[database setValue:@[ root, mid, invoices, payments ] forKey:@"hasQueries"];

	RptqObject *invoicesSource = [source insertObjectForEntity:@"RptqQueryTable" identifier:200];
	[invoicesSource setValue:invoicesTable forKey:@"databaseSchemaTable"];
	[invoicesSource setValue:invoices forKey:@"inQuery"];
	RptqObject *paymentsSource = [source insertObjectForEntity:@"RptqQueryTable" identifier:201];
	[paymentsSource setValue:paymentsTable forKey:@"databaseSchemaTable"];
	[paymentsSource setValue:payments forKey:@"inQuery"];

	RptqObject *midInvoices = [source insertObjectForEntity:@"RptqQueryTable" identifier:202];
	[midInvoices setValue:mid forKey:@"inQuery"];
	[midInvoices setValue:invoices forKey:@"upstreamQuery"];
	RptqObject *midPayments = [source insertObjectForEntity:@"RptqQueryTable" identifier:203];
	[midPayments setValue:mid forKey:@"inQuery"];
	[midPayments setValue:payments forKey:@"upstreamQuery"];

	RptqObject *rootMid = [source insertObjectForEntity:@"RptqQueryTable" identifier:204];
	[rootMid setValue:root forKey:@"inQuery"];
	[rootMid setValue:mid forKey:@"upstreamQuery"];

	[document setValue:root forKey:@"rootQuery"];
	[RptqDocumentSection createStructuralSectionsForQuery:invoices managedObjectContext:source];
	[RptqDocumentSection createStructuralSectionsForQuery:payments managedObjectContext:source];
	[RptqDocumentSection createStructuralSectionsForQuery:mid managedObjectContext:source];
	MAD_PASS([source saveComposed:NULL], "the source saves");

	RptqStoreContext *destination = openContextAtPath(directory, @"nested-destination.sqlite");
	MAD_PASS([destination loadAllWithError:NULL], "the destination loads");
	[destination insertObjectForEntity:@"RptqDocument" identifier:1];

	RptqQuery *importedRoot = [destination importQueryGraphFromContext:source relativePathBaseURL:nil error:NULL];
	MAD_PASS(importedRoot != nil, "the import returns a root");

	MAD_PASS([destination objectsForEntity:@"RptqQuery"].count == (NSUInteger)4, "all four nodes import");
	RptqQuery *importedMid = nil;
	for (RptqObject *object in [destination objectsForEntity:@"RptqQuery"]) {
		RptqQuery *query = (RptqQuery *)object;
		if ([query.name isEqualToString:@"mid"]) importedMid = query;
	}
	MAD_PASS(importedMid != nil, "the intermediate composer imports");
	MAD_PASS([importedMid isComposing], "the intermediate composer is still composing");
	MAD_PASS(importedMid.hasQueryTables.count == (NSUInteger)2, "the intermediate composer keeps its two children");
	for (RptqQueryTable *table in importedMid.hasQueryTables) {
		MAD_PASS(table.upstreamQuery != nil, "each child of the intermediate composer is upstream");
	}
	MAD_PASS(importedMid.hasLayoutSections.count == (NSUInteger)5, "the intermediate composer's five sections import");
	for (RptqDocumentSection *section in importedMid.hasLayoutSections) {
		MAD_PASS_EQUAL(section.ownerQuery.name, @"mid", "each section is owned by the intermediate composer");
	}

	removeTempDirectory(directory);
}

#pragma mark - Composed output-key naming

static RptqQueryField *fieldWithSchemaName(RptqStoreContext *context, NSString *schemaName, NSString *sourceAlias) {
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

static void testComposeOutputKeysBareNamesDisambiguate(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"naming.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqQueryField *invoiceId = fieldWithSchemaName(context, @"invoice_id", @"invoices");
	RptqQueryField *invoiceAmount = fieldWithSchemaName(context, @"amount", @"invoices");
	RptqQueryField *paymentAmount = fieldWithSchemaName(context, @"amount", @"payments");

	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:@[ invoiceId, invoiceAmount, paymentAmount ]
														 existingKeys:[NSSet set]];
	MAD_PASS_EQUAL(keys, (@[ @"invoice_id", @"invoices.amount", @"payments.amount" ]), "colliding bare names qualify with their source alias");

	removeTempDirectory(directory);
}

static void testComposeOutputKeysPreserveExistingAndAvoidTaken(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"naming2.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqQueryField *kept = fieldWithSchemaName(context, @"amount", @"invoices");
	kept.outputKey = @"kept_amount";
	RptqQueryField *newAmount = fieldWithSchemaName(context, @"amount", @"payments");

	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:@[ kept, newAmount ] existingKeys:[NSSet set]];
	MAD_PASS_EQUAL(keys, (@[ @"kept_amount", @"amount" ]), "an established key is preserved and a unique bare name stays bare");

	RptqQueryField *colliding = fieldWithSchemaName(context, @"amount", @"payments");
	NSArray<NSString *> *keys2 = [RptqQuery composeOutputKeysForFields:@[ colliding ] existingKeys:[NSSet setWithArray:@[ @"amount" ]]];
	MAD_PASS_EQUAL(keys2, (@[ @"payments.amount" ]), "a bare name already taken is qualified with its source alias");

	removeTempDirectory(directory);
}

#pragma mark - Converting a standard report to a composition

static void testConvertToCompositionMovesGroupsAndRebindsLabels(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"convert.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

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
	MAD_PASS(root != nil, "convert: %s", [[error description] UTF8String]);
	MAD_PASS([model valueForKey:@"rootQuery"] == root, "the document's root is the new root");
	MAD_PASS_EQUAL([root valueForKey:@"name"], @"root", "the root keeps its name");

	RptqObject *child = [model valueForKey:@"mainQuery"];
	MAD_PASS_EQUAL([child valueForKey:@"name"], @"invoices", "the child is named");
	MAD_PASS([[child valueForKey:@"hasQueryGroups"] count] == (NSUInteger)0, "the child's groups are moved");

	NSSet *rootTables = [root valueForKey:@"hasQueryTables"];
	MAD_PASS(rootTables.count == (NSUInteger)1, "the root has one upstream table");
	RptqObject *rootTable = rootTables.anyObject;
	MAD_PASS([rootTable valueForKey:@"upstreamQuery"] != nil, "the upstream table names the child");
	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:&error];
	MAD_PASS(outputs.count == (NSUInteger)2, "the root projects two fields");
	MAD_PASS_EQUAL(outputs[0].outputKey, @"invoice_id", "the first output keeps its bare name");
	MAD_PASS_EQUAL(outputs[1].outputKey, @"amount", "the second output keeps its bare name");

	NSSet *rootGroups = [root valueForKey:@"hasQueryGroups"];
	MAD_PASS(rootGroups.count == (NSUInteger)1, "the root carries one group");
	MAD_PASS_EQUAL([[rootGroups.anyObject valueForKey:@"hasField"] valueForKey:@"outputKey"], @"invoice_id", "the group binds to the root's invoice_id output");

	RptqObject *rebound = [label valueForKey:@"referencesQueryField"];
	MAD_PASS(rebound.identifier != [[amountQueryField valueForKey:@"identifier"] longLongValue], "the label no longer references the child field");
	MAD_PASS_EQUAL([rebound valueForKey:@"outputKey"], @"amount", "the label rebinds to the root's amount output");

	removeTempDirectory(directory);
}

static void testAddChildQueryProjectsFieldsAndDisambiguatesCollisions(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"addchild.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	RptqObject *document = [context insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqObject *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	[database setValue:@"Sqlite 3" forKey:@"databaseDriverType"];
	[document setValue:@[ database ] forKey:@"hasDatabaseSchemas"];
	RptqObject *root = [context insertObjectForEntity:@"RptqQuery" identifier:100];
	[root setValue:@"root" forKey:@"name"];
	[root setValue:database forKey:@"inDatabase"];
	[document setValue:root forKey:@"rootQuery"];

	RptqObject *invoiceIdField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	[invoiceIdField setValue:@"invoice_id" forKey:@"name"];
	RptqObject *amountField = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:21];
	[amountField setValue:@"amount" forKey:@"name"];

	RptqObject *invoices = [context insertObjectForEntity:@"RptqQuery" identifier:101];
	[invoices setValue:@"invoices" forKey:@"name"];
	[invoices setValue:database forKey:@"inDatabase"];
	RptqObject *invoicesTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:201];
	[invoicesTable setValue:invoices forKey:@"inQuery"];
	RptqObject *iId = [context insertObjectForEntity:@"RptqQueryField" identifier:301];
	[iId setValue:invoiceIdField forKey:@"databaseSchemaField"];
	[iId setValue:invoicesTable forKey:@"inQueryTable"];
	RptqObject *iAmount = [context insertObjectForEntity:@"RptqQueryField" identifier:302];
	[iAmount setValue:amountField forKey:@"databaseSchemaField"];
	[iAmount setValue:invoicesTable forKey:@"inQueryTable"];

	RptqObject *payments = [context insertObjectForEntity:@"RptqQuery" identifier:102];
	[payments setValue:@"payments" forKey:@"name"];
	[payments setValue:database forKey:@"inDatabase"];
	RptqObject *paymentsTable = [context insertObjectForEntity:@"RptqQueryTable" identifier:202];
	[paymentsTable setValue:payments forKey:@"inQuery"];
	RptqObject *pAmount = [context insertObjectForEntity:@"RptqQueryField" identifier:303];
	[pAmount setValue:amountField forKey:@"databaseSchemaField"];
	[pAmount setValue:paymentsTable forKey:@"inQueryTable"];

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	NSError *error = nil;
	MAD_PASS([model addChildQuery:(RptqQuery *)invoices error:&error] != nil, "the first child is added");
	MAD_PASS([model addChildQuery:(RptqQuery *)payments error:&error] != nil, "the second child is added");

	NSArray<RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError:&error];
	MAD_PASS(outputs.count == (NSUInteger)3, "the root projects three fields");
	MAD_PASS_EQUAL(outputs[0].outputKey, @"invoice_id", "the first output is invoice_id");
	MAD_PASS_EQUAL(outputs[1].outputKey, @"amount", "the first amount stays bare");
	MAD_PASS_EQUAL(outputs[2].outputKey, @"payments.amount", "the colliding amount is qualified");

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
	MAD_TEST(testDeleteIsPendingUntilSave),
	MAD_TEST(testCompositionGraphRoundTripsAndIsRevision3),
	MAD_TEST(testOrdinaryReportStaysRevision2),
	MAD_TEST(testFailedCompositionSaveRollsBackToRevision2),
	MAD_TEST(testCompositionGraphValidation),
	MAD_TEST(testComposedArchiveRoundTrip),
	MAD_TEST(testComposedProjectionReorder),
	MAD_TEST(testComposedSaveAs),
	MAD_TEST(testComposedFailedArchivePreservesDestination),
	MAD_TEST(testImportQueryGraphRemapsIdentifiersAndResolvesRelativePath),
	MAD_TEST(testImportComposedGraphBringsRootAndLeaves),
	MAD_TEST(testPerNodeLayoutRoundTripsWithThreeLayouts),
	MAD_TEST(testImportLayoutlessSourceYieldsEmptySections),
	MAD_TEST(testImportCopiesSourceLayout),
	MAD_TEST(testImportLayoutWithElementsRemapsFieldRefs),
	MAD_TEST(testImportNestedFourNodeGraph),
	MAD_TEST(testComposeOutputKeysBareNamesDisambiguate),
	MAD_TEST(testComposeOutputKeysPreserveExistingAndAvoidTaken),
	MAD_TEST(testConvertToCompositionMovesGroupsAndRebindsLabels),
	MAD_TEST(testAddChildQueryProjectsFieldsAndDisambiguatesCollisions));
