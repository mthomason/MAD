//
//  MysqlSupportTypesTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MysqlSupportTypesTests.m: offline coverage for
//  the two small carrier types in MADMySQL: MysqlIndex, which only remembers
//  the connection it was built with, and MysqlLiteral, the string wrapper the
//  driver hands back for quoted literals.
//

#import "MADTestSupport.h"

#import <MADMySQL/MysqlIndex.h>
#import <MADMySQL/MysqlLiteral.h>
#import <MADMySQL/MysqlConnection.h>

static MysqlConnection *connectionWithoutAServer(void) {
	return [[MysqlConnection alloc] init];
}

#pragma mark - MysqlIndex

static void testIndexFactoryKeepsTheConnection(void) {
	MysqlConnection *connection = connectionWithoutAServer();

	MysqlIndex *index = [MysqlIndex indexWithConnection:connection];

	MAD_PASS(index != nil, "the factory vends an index");
	MAD_PASS(index.connection == connection, "the index holds the connection it was built with");
}

static void testIndexAcceptsANilConnection(void) {
	MysqlIndex *index = [MysqlIndex indexWithConnection:nil];

	MAD_PASS(index != nil, "the factory vends an index even for a nil connection");
	MAD_PASS(index.connection == nil, "and holds nothing");
}

#pragma mark - MysqlLiteral

static void testLiteralCopiesItsString(void) {
	NSMutableString *source = [NSMutableString stringWithString:@"O'Brien"];
	MysqlLiteral *literal = [MysqlLiteral literalWithString:source];

	[source appendString:@" and more"];

	// The literal took a copy: the caller's later edits do not show up.
	MAD_PASS_EQUAL(literal.string, @"O'Brien", "the literal copied the string");
}

static void testLiteralWithNilStringAnswersNil(void) {
	MysqlLiteral *literal = [MysqlLiteral literalWithString:nil];

	MAD_PASS(literal != nil, "the factory still vends a literal");
	MAD_PASS(literal.string == nil, "for a nil string the literal is nil");
}

static void testLiteralWithAnEmptyStringIsEmpty(void) {
	MysqlLiteral *literal = [MysqlLiteral literalWithString:@""];

	MAD_PASS_EQUAL(literal.string, @"", "an empty string stays empty");
}

MAD_TEST_MAIN("MysqlSupportTypesTests",
	MAD_TEST(testIndexFactoryKeepsTheConnection),
	MAD_TEST(testIndexAcceptsANilConnection),
	MAD_TEST(testLiteralCopiesItsString),
	MAD_TEST(testLiteralWithNilStringAnswersNil),
	MAD_TEST(testLiteralWithAnEmptyStringIsEmpty));
