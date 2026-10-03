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
#import <MAD/MADStoreConverter.h>

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
	NSArray *databases = [readDocument valueForKey:@"hasDatabaseSchemas"];
	XCTAssertEqual(databases.count, (NSUInteger)1);

	RptqObject *readDatabase = databases.firstObject;
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

	NSArray *tables = [readDatabase valueForKey:@"hasTables"];
	XCTAssertEqual(tables.count, (NSUInteger)2);

	RptqObject *readCustomers = nil;
	for (RptqObject *table in tables) {
		RptqObject *owningDatabase = [table valueForKey:@"inDatabase"];
		XCTAssertEqual(owningDatabase.identifier, readDatabase.identifier);
		if ([[table valueForKey:@"name"] isEqualToString:@"customers"]) readCustomers = table;
	}
	XCTAssertNotNil(readCustomers);
	XCTAssertEqualObjects([readCustomers valueForKey:@"queryable"], @YES);

	NSArray *fields = [readCustomers valueForKey:@"hasFields"];
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
	NSArray *tables = [database valueForKey:@"hasTables"];
	XCTAssertEqual(tables.count, (NSUInteger)11);

	NSUInteger fields = 0;
	for (RptqObject *table in tables) {
		RptqObject *owningDatabase = [table valueForKey:@"inDatabase"];
		XCTAssertEqual(owningDatabase.identifier, database.identifier);
		fields += [[table valueForKey:@"hasFields"] count];
	}
	XCTAssertEqual(fields, (NSUInteger)64);
}

@end
