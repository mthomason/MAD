//
//  MADQueryMaxFieldLengthTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryMaxFieldLengthTests.m: the query that asks a
//  database for the longest value in each field, used to size columns for the
//  sample-data preview.  The fixture wires a schema field through its table to a
//  database whose driver type is MySQL; -initWithObject: turns the credential
//  chain into a connection and then a database, and what -getSql: emits is pure
//  string assembly through that database's dialect helpers, so no connection is
//  ever opened.  The Xcode suite's in-memory Core Data context is a real SQLite
//  store under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQueryType.h>

#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADQueryMaxFieldLength.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
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

static RptqDatabaseSchemaField *invoiceNameFieldInContext(RptqStoreContext *context) {
	RptqDatabase *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	database.databaseDriverTypeEnum = MADDatabaseTypeMySQL;

	RptqDatabaseCredentals *credentials = [context insertObjectForEntity:@"RptqDatabaseCredentals" identifier:0];
	// The credential's protocol property derives its database type from driverID
	// (RptqDatabaseCredentals+MADDatabaseConnection.m), not from the enum above.
	credentials.driverID = [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL];
	credentials.dbname = @"testdb";
	credentials.host = @"localhost";
	credentials.port = 3306;
	database.ownedByUser = credentials;

	RptqDatabaseSchemaTable *table = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																												name:@"Invoice"
																										andQueryable:YES];
	table.inDatabase = database;

	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:@"Name"];
	databaseField.fieldType = MADDataTypeString;
	RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																										   andField:databaseField];
	field.inTable = table;
	return field;
}

#pragma mark - Tests

static void testSqlSelectsTheMaxLengthOfEachField(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaField *field = invoiceNameFieldInContext(context);
	NSOrderedSet *fields = [NSOrderedSet orderedSetWithObject:field];
	MADQueryMaxFieldLength *query = [[MADQueryMaxFieldLength alloc] initWithObject:fields];

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	MAD_PASS(error == nil, "the SQL builds without error");
	// The MySQL dialect: both the key and the table reference are back-ticked, and the
	// connector carries its own spaces (hence the doubled ones).
	MAD_PASS_EQUAL(sql, @"SELECT\n  MAX( LENGTH(`Invoice`.`Name`) )  AS  NameInvoice \nFROM\n `Invoice`;", "the max-length SQL");
	MAD_PASS(query.type == MADQueryTypeMaxFieldLength, "the query type is max-field-length");
	// The alias map and key list are filled while the SQL is built.
	MAD_PASS_EQUAL(query.fieldKeys, (@[@"NameInvoice"]), "the field keys are collected");
	MAD_PASS([query.fields[@"NameInvoice"] isKindOfClass:[MADDatabaseField class]], "the alias map holds the database field");
}

static void testInitWithANonSchemaFieldAsserts(void) {
	// The initializer requires the ordered set's first member to be a schema field.
	NSOrderedSet *notAField = [NSOrderedSet orderedSetWithObject:@"Name"];
	MAD_THROWS_NAMED(([[MADQueryMaxFieldLength alloc] initWithObject:notAField]),
					 NSInternalInconsistencyException,
					 "a non-schema field trips the initializer's assertion");
}

MAD_TEST_MAIN("MADQueryMaxFieldLengthTests",
	MAD_TEST(testSqlSelectsTheMaxLengthOfEachField),
	MAD_TEST(testInitWithANonSchemaFieldAsserts));
