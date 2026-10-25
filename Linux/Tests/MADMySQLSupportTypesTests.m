//
//  MADMySQLSupportTypesTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLSupportTypesTests.m: offline coverage for
//  the two small carrier types in MADMySQL: MADMySQLIndex, which only remembers
//  the connection it was built with, and MADMySQLLiteral, the string wrapper the
//  driver hands back for quoted literals.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADMySQLIndex.h>
#import <MADMySQL/MADMySQLLiteral.h>
#import <MADMySQL/MADMySQLConnection.h>

static MADMySQLConnection *connectionWithoutAServer(void) {
	return [[MADMySQLConnection alloc] init];
}

#pragma mark - MADMySQLIndex

static void testIndexFactoryKeepsTheConnection(void) {
	MADMySQLConnection *connection = connectionWithoutAServer();

	MADMySQLIndex *index = [MADMySQLIndex indexWithConnection:connection];

	MAD_PASS(index != nil, "the factory vends an index");
	MAD_PASS(index.connection == connection, "the index holds the connection it was built with");
}

static void testIndexAcceptsANilConnection(void) {
	MADMySQLIndex *index = [MADMySQLIndex indexWithConnection:nil];

	MAD_PASS(index != nil, "the factory vends an index even for a nil connection");
	MAD_PASS(index.connection == nil, "and holds nothing");
}

#pragma mark - MADMySQLLiteral

static void testLiteralCopiesItsString(void) {
	NSMutableString *source = [NSMutableString stringWithString:@"O'Brien"];
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:source];

	[source appendString:@" and more"];

	// The literal took a copy: the caller's later edits do not show up.
	MAD_PASS_EQUAL(literal.string, @"O'Brien", "the literal copied the string");
}

static void testLiteralWithNilStringAnswersNil(void) {
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:nil];

	MAD_PASS(literal != nil, "the factory still vends a literal");
	MAD_PASS(literal.string == nil, "for a nil string the literal is nil");
}

static void testLiteralWithAnEmptyStringIsEmpty(void) {
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:@""];

	MAD_PASS_EQUAL(literal.string, @"", "an empty string stays empty");
}

MAD_TEST_MAIN("MADMySQLSupportTypesTests",
	MAD_TEST(testIndexFactoryKeepsTheConnection),
	MAD_TEST(testIndexAcceptsANilConnection),
	MAD_TEST(testLiteralCopiesItsString),
	MAD_TEST(testLiteralWithNilStringAnswersNil),
	MAD_TEST(testLiteralWithAnEmptyStringIsEmpty));
