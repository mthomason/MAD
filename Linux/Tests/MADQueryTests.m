//
//  MADQueryTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADQueryTests.m: the base class for all query
//  types -- its getSql: variants clear the field key/value state on
//  subclasses that adopt MADQueryFieldKeysProtocol, and fieldKeyForIndex:
//  resolves keys from that same protocol.  The small test subclass provides
//  the protocol storage so those behaviors can be exercised.
//

#import "MADTestSupport.h"
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabase.h>

@interface MADTestQuery : MADQuery <MADQueryFieldKeysProtocol, MADQueryDatabaseProtocol>
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *fields;
@property (nonatomic, strong) NSMutableArray *fieldKeys;
@property (nonatomic, strong) MADDatabase *database;
@end

@implementation MADTestQuery
@synthesize fields = _fields;
@synthesize fieldKeys = _fieldKeys;
@synthesize database = _database;
@end

#pragma mark - Base-class defaults

static void testBaseDefaults(void) {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	MAD_PASS(query != nil, "the query exists");
	MAD_PASS(query.returnsResults, "the base class returns results");
	MAD_PASS(!query.partOfTransactionSet, "the base class is not part of a transaction set");
}

static void testGetSqlReturnsEmptyString(void) {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	NSError *error = nil;
	MAD_PASS_EQUAL([query getSql:&error], @"", "the base SQL is empty");
	MAD_PASS(error == nil, "no error from the base SQL");
}

static void testGetSqlWithDatabaseReturnsEmptyString(void) {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	NSError *error = nil;
	MAD_PASS_EQUAL([query getSql:nil error:&error], @"", "the base SQL with a database is empty");
	MAD_PASS(error == nil, "no error from the base SQL");
}

#pragma mark - Field-key resolution

static void testFieldKeyForIndex(void) {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fieldKeys = [@[@"a", @"b", @"c"] mutableCopy];

	MAD_PASS_EQUAL([query fieldKeyForIndex:0], @"a", "index 0 resolves");
	MAD_PASS_EQUAL([query fieldKeyForIndex:2], @"c", "index 2 resolves");
	MAD_PASS([query fieldKeyForIndex:3] == nil, "an out-of-range index is nil");
	MAD_PASS([query fieldKeyForIndex:100] == nil, "a far index is nil");
}

static void testFieldKeyForIndexWithNilFieldKeys(void) {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fieldKeys = nil;
	MAD_PASS([query fieldKeyForIndex:0] == nil, "no keys means no resolution");
}

#pragma mark - Field/keys state clearing

static void testGetSqlClearsFieldsAndKeys(void) {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fields = [@{@"c": @"v"} mutableCopy];
	query.fieldKeys = [@[@"c"] mutableCopy];

	NSError *error = nil;
	[query getSql:&error];

	MAD_PASS(query.fields.count == (NSUInteger)0, "the fields are cleared");
	MAD_PASS(query.fieldKeys.count == (NSUInteger)0, "the keys are cleared");
	MAD_PASS(error == nil, "no error from the clearing getSql");
}

#pragma mark - Database injection

static void testGetSqlWithDatabaseSetsDatabase(void) {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	MADDatabase *database = [[MADDatabase alloc] init];

	NSError *error = nil;
	[query getSql:database error:&error];

	MAD_PASS(query.database == database, "the database is injected");
	MAD_PASS(error == nil, "no error from the injecting getSql");
}

MAD_TEST_MAIN("MADQueryTests",
	MAD_TEST(testBaseDefaults),
	MAD_TEST(testGetSqlReturnsEmptyString),
	MAD_TEST(testGetSqlWithDatabaseReturnsEmptyString),
	MAD_TEST(testFieldKeyForIndex),
	MAD_TEST(testFieldKeyForIndexWithNilFieldKeys),
	MAD_TEST(testGetSqlClearsFieldsAndKeys),
	MAD_TEST(testGetSqlWithDatabaseSetsDatabase));
