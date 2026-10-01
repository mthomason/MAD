//
//  MADDesignerUnitTests.m
//  MADDesignerUnitTests
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  Non-UI tests for the app. This bundle is hosted by `MAD Designer.app`
//  (TEST_HOST/BUNDLE_LOADER are set), so it can reach two things the framework test
//  bundles cannot: the app's own source, and the MAD frameworks exactly as the app
//  links them.
//
//  The first group covers app-source helper categories. Those live in the app
//  target's Sources phase, so they are reached through the host rather than imported:
//  the categories are declared locally here to describe the interface, and the
//  symbols resolve against the running app at load time.
//
//  The second group covers framework consumption -- the same construction and SQL
//  generation the app does when it opens a connection, which is the part of the
//  integration that is worth pinning independently of any live server.
//
//  The original contents of this file were the Xcode template stubs plus a
//  `testExample` that opened a live RDS instance in us-east-1 with hardcoded
//  credentials. That host no longer resolves and the APIs it used no longer exist, so
//  it had not compiled in some time. It is replaced below by tests that need no server;
//  the live path is covered by the framework suites (MADMySQLTests, MADTdsClientTests).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQuery.h>

#import <MAD/MADQueryTest.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>

// App-source categories. Declared rather than imported because the app's Source
// directory is not on this bundle's header search path; the implementations are in
// the host app.
@interface NSData (MADDesignerUnitTestsBase64)
+ (NSData *)dataFromBase64String:(NSString *)aString;
- (NSString *)base64EncodedString;
@end

@interface NSDateFormatter (MADDesignerUnitTestsRFC3339)
+ (instancetype)RFC_3339;
@end

@interface MADDesignerUnitTests : XCTestCase
@end

@implementation MADDesignerUnitTests

#pragma mark - App source: NSData (Base64)

- (void)testBase64DecodeOfKnownString {
	NSData *decoded = [NSData dataFromBase64String:@"aGVsbG8="];
	XCTAssertEqualObjects([[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding], @"hello");
}

- (void)testBase64EncodeOfKnownString {
	NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects([data base64EncodedString], @"aGVsbG8=");
}

- (void)testBase64RoundTrip {
	NSData *original = [@"The quick brown fox jumps over the lazy dog" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *decoded = [NSData dataFromBase64String:[original base64EncodedString]];
	XCTAssertEqualObjects(decoded, original);
}

- (void)testBase64EncodeOfEmptyData {
	XCTAssertEqualObjects([NSData data].base64EncodedString, @"");
}

- (void)testBase64DecodeOfEmptyString {
	XCTAssertEqual([NSData dataFromBase64String:@""].length, (NSUInteger)0);
}

// An encoded length that is not a multiple of 4 still decodes, and no longer writes past
// the output buffer. The decoder used to size that buffer as `(length / 4) * 3` while
// the store loop always wrote 3 bytes per group, so a five-character input got a 3-byte
// buffer and the trailing character wrote at offsets 3, 4 and 5. The overrun landed in
// malloc's slack -- the returned NSData is built from the separately tracked length, so
// the decoded value was already correct -- which is why it needed inspection rather than
// a test to find. The assertions below pin the value; the buffer sizing is checked by
// reading NewBase64Decode.
- (void)testBase64DecodeOfTruncatedInput {
	NSData *decoded = [NSData dataFromBase64String:@"YWJjY"];

	XCTAssertEqual(decoded.length, (NSUInteger)3);
	XCTAssertEqualObjects([[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding], @"abc");
}

#pragma mark - App source: NSDateFormatter (RFC_3339)

- (void)testRFC3339FormatterFormat {
	NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
	XCTAssertEqualObjects([[NSDateFormatter RFC_3339] stringFromDate:epoch], @"1970-01-01T00:00:00Z");
}

- (void)testRFC3339FormatterParsesAndRoundTrips {
	NSDateFormatter *formatter = [NSDateFormatter RFC_3339];
	NSDate *parsed = [formatter dateFromString:@"2020-01-15T13:45:00Z"];

	XCTAssertNotNil(parsed);
	XCTAssertEqualWithAccuracy(parsed.timeIntervalSince1970, 1579095900.0, 0.5);
	XCTAssertEqualObjects([formatter stringFromDate:parsed], @"2020-01-15T13:45:00Z");
}

// RFC 3339 permits both the `Z` spelling of UTC and a numeric offset. The format string
// used to end in a literal 'Z', so only the former was accepted and a server timestamp
// carrying an offset was silently dropped.
- (void)testRFC3339FormatterAcceptsAnExplicitNumericOffset {
	NSDateFormatter *formatter = [NSDateFormatter RFC_3339];

	XCTAssertNotNil([formatter dateFromString:@"2020-01-15T13:45:00Z"]);

	NSDate *offset = [formatter dateFromString:@"2020-01-15T13:45:00+02:00"];
	XCTAssertNotNil(offset);
	// 13:45 at +02:00 is 11:45 UTC.
	XCTAssertEqualWithAccuracy(offset.timeIntervalSince1970, 1579088700.0, 0.5);
}

#pragma mark - Framework consumption: connections

- (void)testMySQLConnectionProperties {
	MADDatabaseConnectionMySql *connection = [[MADDatabaseConnectionMySql alloc] initWithHost:@"localhost"
																					database:@"employees"
																					 andPort:3306];

	XCTAssertEqual(connection.databaseType, MADDatabaseTypeMySQL);
	XCTAssertTrue(connection.requiresCredentials);
	XCTAssertNotNil(connection.connectionString);
	XCTAssertNotNil(connection.identifier);
}

#pragma mark - Framework consumption: SQL generation

// MADQueryTest is the connection-test query the app runs before it will accept a new
// connection. It builds its statement from the MADDatabase it is handed, so this pins
// the SQL text without touching a server.
- (void)testQueryTestGeneratesMySQLStatement {
	MADDatabaseMySQL *database = [[MADDatabaseMySQL alloc] init];
	database.databaseConnection = [[MADDatabaseConnectionMySql alloc] initWithHost:@"localhost"
																		 database:@"employees"
																		  andPort:3306];

	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:database];
	query.database = database;

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(error);
	XCTAssertNotNil(sql);
	XCTAssertTrue([sql containsString:@"SELECT"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"255"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"`f1`"], @"Got: %@", sql);
}

// -initWithObject: deliberately ignores its argument -- the database has to be assigned
// afterwards. Without it the statement is built from a nil database and comes out as
// literal "(null)" text rather than failing loudly.
- (void)testQueryTestWithoutADatabaseProducesGarbageSQL {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:[[MADDatabaseMySQL alloc] init]];

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(query.database);
	XCTAssertNotNil(sql);
	XCTAssertTrue([sql containsString:@"(null)"], @"Got: %@", sql);
}

@end
