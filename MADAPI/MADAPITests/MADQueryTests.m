//
//  MADQueryTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for MADQuery, the base class for all query types.  The base
//  class carries no fields, but its getSql: variants clear the field key/value
//  state on subclasses that adopt MADQueryFieldKeysProtocol, and its
//  fieldKeyForIndex: resolves keys from that same protocol.  A small test
//  subclass provides the protocol storage so these behaviors can be exercised.
//

#import <XCTest/XCTest.h>

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

// A query that fails the way a driver's parser would: it sets the error and still
// returns whatever SQL it managed to build.
@interface MADFailingQuery : MADQuery
@property (nonatomic, assign) BOOL sawNullErrorPointer;
@end

@implementation MADFailingQuery

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	if (error == NULL) {
		self.sawNullErrorPointer = YES;
		return @"";
	}
	*error = [NSError errorWithDomain:@"MADTestQuery" code:7 userInfo:nil];
	return @"SELECT partial";
}

@end

@interface MADQueryTests : XCTestCase
@end

@implementation MADQueryTests

#pragma mark - Base-class defaults

- (void)testBaseDefaults {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	XCTAssertNotNil(query);
	XCTAssertTrue(query.returnsResults);
	XCTAssertFalse(query.partOfTransactionSet);
}

- (void)testGetSqlReturnsEmptyString {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	NSError *error = nil;
	XCTAssertEqualObjects([query getSql:&error], @"");
	XCTAssertNil(error);
}

- (void)testGetSqlWithDatabaseReturnsEmptyString {
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	NSError *error = nil;
	XCTAssertEqualObjects([query getSql:nil error:&error], @"");
	XCTAssertNil(error);
}

#pragma mark - Field-key resolution

- (void)testFieldKeyForIndex {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fieldKeys = [@[@"a", @"b", @"c"] mutableCopy];

	XCTAssertEqualObjects([query fieldKeyForIndex:0], @"a");
	XCTAssertEqualObjects([query fieldKeyForIndex:2], @"c");
	XCTAssertNil([query fieldKeyForIndex:3]);
	XCTAssertNil([query fieldKeyForIndex:100]);
}

- (void)testFieldKeyForIndexWithNilFieldKeys {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fieldKeys = nil;
	XCTAssertNil([query fieldKeyForIndex:0]);
}

#pragma mark - Field/keys state clearing

- (void)testGetSqlClearsFieldsAndKeys {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	query.fields = [@{@"c": @"v"} mutableCopy];
	query.fieldKeys = [@[@"c"] mutableCopy];

	NSError *error = nil;
	[query getSql:&error];

	XCTAssertEqual(query.fields.count, (NSUInteger)0);
	XCTAssertEqual(query.fieldKeys.count, (NSUInteger)0);
	XCTAssertNil(error);
}

#pragma mark - Database injection

- (void)testGetSqlWithDatabaseSetsDatabase {
	MADTestQuery *query = [[MADTestQuery alloc] initWithObject:nil];
	MADDatabase *database = [[MADDatabase alloc] init];

	NSError *error = nil;
	[query getSql:database error:&error];

	XCTAssertEqual(query.database, database);
	XCTAssertNil(error);
}

#pragma mark - Error propagation

- (void)testGetSqlWithDatabasePropagatesSubclassError {
	MADFailingQuery *query = [[MADFailingQuery alloc] initWithObject:nil];

	NSError *error = nil;
	NSString *sql = [query getSql:nil error:&error];

	// The SQL a failing build managed to produce is still handed back.
	XCTAssertEqualObjects(sql, @"SELECT partial");
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 7);
	XCTAssertEqualObjects(error.domain, @"MADTestQuery");
}

- (void)testGetSqlWithDatabaseToleratesNullErrorPointer {
	MADFailingQuery *query = [[MADFailingQuery alloc] initWithObject:nil];

	// The two-argument form always hands its callee a local error pointer, so the
	// failure is dropped on the floor rather than crashing.
	XCTAssertEqualObjects([query getSql:nil error:NULL], @"SELECT partial");
}

- (void)testGetSqlToleratesNullErrorPointer {
	MADFailingQuery *query = [[MADFailingQuery alloc] initWithObject:nil];

	// A direct caller of the one-argument form may pass NULL; the callee must check.
	XCTAssertNoThrow([query getSql:NULL]);
	XCTAssertTrue(query.sawNullErrorPointer);
}

#pragma mark - Field keys without the protocol

- (void)testFieldKeyForIndexWithoutFieldKeysProtocol {
	// The base class does not adopt MADQueryFieldKeysProtocol, so there is nothing to
	// resolve against.
	MADQuery *query = [[MADQuery alloc] initWithObject:nil];
	XCTAssertNil([query fieldKeyForIndex:0]);
}

@end
