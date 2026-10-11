//
//  MADQueryMaxFieldLengthTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADQueryMaxFieldLength: the query that asks a database for the
//  longest value in each field, used to size columns for the sample-data preview.
//
//  The fixture wires a schema field through its table to a database whose driver type
//  is MySQL.  -initWithObject: turns the credential chain into a connection and then
//  a database, and what -getSql: emits is pure string assembly through that
//  database's dialect helpers, so no connection is ever opened.  (Both the base
//  +newDatabaseWithConnection: and the dispatcher in MADDatabase+Constructor produce
//  the same SQL for this input -- base and MySQL agree on every helper this class
//  calls -- so the assertion holds whichever implementation the runtime picks.)
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQueryType.h>

#import "MADDatabaseConnection+Constructor.h"
#import "MADQuery+Extras.h"
#import "MADQueryMaxFieldLength.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDatabase.h"
#import "RptqDatabaseCredentals.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

@interface MADQueryMaxFieldLengthTests : XCTestCase
@end

@implementation MADQueryMaxFieldLengthTests

#pragma mark - Fixture

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDatabaseSchemaField *)invoiceNameFieldInContext:(RptqStoreContext *)context {
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

- (void)testSqlSelectsTheMaxLengthOfEachField {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaField *field = [self invoiceNameFieldInContext:context];
	NSOrderedSet *fields = [NSOrderedSet orderedSetWithObject:field];
	MADQueryMaxFieldLength *query = [[MADQueryMaxFieldLength alloc] initWithObject:fields];

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(error);
	// The MySQL dialect: both the key and the table reference are back-ticked, and the
	// connector carries its own spaces (hence the doubled ones).
	XCTAssertEqualObjects(sql, @"SELECT\n  MAX( LENGTH(`Invoice`.`Name`) )  AS  NameInvoice \nFROM\n `Invoice`;");
	XCTAssertEqual(query.type, MADQueryTypeMaxFieldLength);
	// The alias map and key list are filled while the SQL is built.
	XCTAssertEqualObjects(query.fieldKeys, (@[@"NameInvoice"]));
	XCTAssertTrue([query.fields[@"NameInvoice"] isKindOfClass:[MADDatabaseField class]]);
}

- (void)testInitWithANonSchemaFieldAsserts {
	// The initializer requires the ordered set's first member to be a schema field.
	NSOrderedSet *notAField = [NSOrderedSet orderedSetWithObject:@"Name"];
	XCTAssertThrowsSpecificNamed(([[MADQueryMaxFieldLength alloc] initWithObject:notAField]),
								 NSException, NSInternalInconsistencyException);
}

@end
