//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCoreLogicTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADCoreLogicTests.m: Tier 1 (pure-logic / value-type)
//  coverage for the MAD framework.  These types carry no Core Data or database
//  state, so they can be exercised directly:
//    * madmath C helpers (digit counting, absolute value).
//    * MADAlignment (MADAlignmentMake / MADAlignmentMake64 + the class).
//    * MADSectionRepresentation (constructors, copy, secure coding round-trip).
//    * MADTableFieldIdentifier / MADTableFieldReference.
//    * NSPredicate+Creators (predicate builders).
//    * Enum + string-constant value contracts (MADPredicateOperator, MADSortOrder,
//      MADQueryLinkType, MADSQLJoinType, MADocumentSectionType).
//
//  The Xcode suite's secure-coding round trip runs on the permissive path off
//  Apple, as the toolchain probe records (see Linux/Tests/MADBorderStyleTests.m).
//

#import "MADTestSupport.h"

#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#include <limits.h>

#import <MADAPI/MADQuery.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADSqlite3/MADQuerySelectParameters.h>

#import <MAD/madmath.h>
#import <MAD/MADQueryCacheSelectGroupKeys.h>
#import <MAD/MADAlignment.h>
#import <MAD/MADSectionRepresentation.h>
#import <MAD/MADTableFieldIdentifier.h>
#import <MAD/NSPredicate+Creators.h>

// GNUstep's -[NSPredicate predicateFormat] renders equality as "=" and a nil
// constant as "(null)"; Apple renders "==" and "nil".  The predicates the
// creators build are the same on both platforms -- only the description
// differs -- so the expected strings follow the platform.
#if __APPLE__
#define MADPredicateFormatEqual @"=="
#define MADPredicateFormatNil	@"nil"
#else
#define MADPredicateFormatEqual @"="
#define MADPredicateFormatNil	@"(null)"
#endif
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADSQLJoinType.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADocumentSectionType.h>

#pragma mark - madmath

static void testDigitCountRecurInt(void) {
	MAD_PASS(digit_count_recur_int(0) == 1, "zero is one digit");
	MAD_PASS(digit_count_recur_int(5) == 1, "5 is one digit");
	MAD_PASS(digit_count_recur_int(9) == 1, "9 is one digit");
	MAD_PASS(digit_count_recur_int(10) == 2, "10 is two digits");
	MAD_PASS(digit_count_recur_int(99) == 2, "99 is two digits");
	MAD_PASS(digit_count_recur_int(100) == 3, "100 is three digits");
	MAD_PASS(digit_count_recur_int(123456) == 6, "123456 is six digits");
}

static void testDigitCountRecurIntNegative(void) {
	MAD_PASS(digit_count_recur_int(-1) == 1, "-1 is one digit");
	MAD_PASS(digit_count_recur_int(-9) == 1, "-9 is one digit");
	MAD_PASS(digit_count_recur_int(-10) == 2, "-10 is two digits");
	MAD_PASS(digit_count_recur_int(-123456) == 6, "-123456 is six digits");
}

static void testDigitCountRecurIntBounds(void) {
	MAD_PASS(digit_count_recur_int(INT_MAX) == 10, "INT_MAX is ten digits");
	// INT_MIN divides before negating, so the count does not depend on
	// INT_MAX's digit count and nothing overflows.
	MAD_PASS(digit_count_recur_int(INT_MIN) == 10, "INT_MIN is ten digits");
}

static void testDigitCountRecurUint(void) {
	MAD_PASS(digit_count_recur_uint(0) == 1, "zero is one digit");
	MAD_PASS(digit_count_recur_uint(9) == 1, "9 is one digit");
	MAD_PASS(digit_count_recur_uint(10) == 2, "10 is two digits");
	MAD_PASS(digit_count_recur_uint(UINT_MAX) == 10, "UINT_MAX is ten digits");
}

static void testDigitCountIterativeInt(void) {
	MAD_PASS(digit_count_iterative_int(0) == 1, "zero is one digit");
	MAD_PASS(digit_count_iterative_int(9) == 1, "9 is one digit");
	MAD_PASS(digit_count_iterative_int(10) == 2, "10 is two digits");
	MAD_PASS(digit_count_iterative_int(-10) == 2, "-10 is two digits");
	MAD_PASS(digit_count_iterative_int(123456) == 6, "123456 is six digits");
	MAD_PASS(digit_count_iterative_int(-123456) == 6, "-123456 is six digits");
}

static void testDigitCountIterativeIntBounds(void) {
	MAD_PASS(digit_count_iterative_int(INT_MAX) == 10, "INT_MAX is ten digits");
	// INT_MIN is collapsed onto INT_MAX before counting (implementation quirk).
	MAD_PASS(digit_count_iterative_int(INT_MIN) == 10, "INT_MIN is ten digits");
}

static void testDigitCountIterativeUint(void) {
	MAD_PASS(digit_count_iterative_uint(0) == 1, "zero is one digit");
	MAD_PASS(digit_count_iterative_uint(9) == 1, "9 is one digit");
	MAD_PASS(digit_count_iterative_uint(10) == 2, "10 is two digits");
	MAD_PASS(digit_count_iterative_uint(UINT_MAX) == 10, "UINT_MAX is ten digits");
}

static void testAbsoluteValueFunctions(void) {
	MAD_PASS(i32abs(0) == 0, "i32abs(0)");
	MAD_PASS(i32abs(5) == 5, "i32abs(5)");
	MAD_PASS(i32abs(-5) == 5, "i32abs(-5)");

	MAD_PASS(i64abs(0) == 0, "i64abs(0)");
	MAD_PASS(i64abs(123) == 123, "i64abs(123)");
	MAD_PASS(i64abs(-123) == 123, "i64abs(-123)");
}

#pragma mark - MADAlignment

static void testHorizontalAlignmentEnumValues(void) {
	MAD_PASS(MADHorizontalAlignmentUnknown == -1, "Unknown is -1");
	MAD_PASS(MADHorizontalAlignmentLeft == 0, "Left is 0");
	MAD_PASS(MADHorizontalAlignmentCenter == 1, "Center is 1");
	MAD_PASS(MADHorizontalAlignmentRight == 2, "Right is 2");
	MAD_PASS(MADHorizontalAlignmentJustified == 3, "Justified is 3");
	MAD_PASS(MADHorizontalAlignmentNatrual == 4, "Natrual is 4");
}

static void testVerticalAlignmentEnumValues(void) {
	MAD_PASS(MADVerticalAlignmentUnknown == -1, "Unknown is -1");
	MAD_PASS(MADVerticalAlignmentTop == 0, "Top is 0");
	MAD_PASS(MADVerticalAlignmentCenter == 1, "Center is 1");
	MAD_PASS(MADVerticalAlignmentBottom == 2, "Bottom is 2");
}

static void testAlignmentMakeAndMake64(void) {
	MADAlignment_t a = MADAlignmentMake(MADHorizontalAlignmentCenter, MADVerticalAlignmentBottom);
	MAD_PASS(a.horizontal == MADHorizontalAlignmentCenter, "Make keeps the horizontal value");
	MAD_PASS(a.vertical == MADVerticalAlignmentBottom, "Make keeps the vertical value");

	// MADAlignmentMake64 maps each valid raw value straight through.
	MADAlignment_t b = MADAlignmentMake64(MADHorizontalAlignmentJustified, MADVerticalAlignmentCenter);
	MAD_PASS(b.horizontal == MADHorizontalAlignmentJustified, "Make64 keeps Justified");
	MAD_PASS(b.vertical == MADVerticalAlignmentCenter, "Make64 keeps Center");

	// Unknown raw values fall back to Left / Top.
	MADAlignment_t c = MADAlignmentMake64(999, 999);
	MAD_PASS(c.horizontal == MADHorizontalAlignmentLeft, "an unknown horizontal falls back to Left");
	MAD_PASS(c.vertical == MADVerticalAlignmentTop, "an unknown vertical falls back to Top");
}

static void testAlignmentClass(void) {
	MADAlignment *alignment = [[MADAlignment alloc] initWithHorizontal:MADHorizontalAlignmentLeft
															  vertical:MADVerticalAlignmentTop];
	MAD_PASS(alignment.horizontal == MADHorizontalAlignmentLeft, "the initial horizontal");
	MAD_PASS(alignment.vertical == MADVerticalAlignmentTop, "the initial vertical");

	alignment.horizontal = MADHorizontalAlignmentRight;
	alignment.vertical = MADVerticalAlignmentBottom;
	MAD_PASS(alignment.horizontal == MADHorizontalAlignmentRight, "the horizontal setter");
	MAD_PASS(alignment.vertical == MADVerticalAlignmentBottom, "the vertical setter");
}

#pragma mark - MADSectionRepresentation / MADocumentSectionType

static void testDocumentSectionTypeEnumValues(void) {
	MAD_PASS(MADDocumentSectionTypeUnknown == 0, "Unknown is 0");
	MAD_PASS(MADDocumentSectionTypeReportHeader == 1, "ReportHeader is 1");
	MAD_PASS(MADDocumentSectionTypeReportFooter == 2, "ReportFooter is 2");
	MAD_PASS(MADDocumentSectionTypePageHeader == 3, "PageHeader is 3");
	MAD_PASS(MADDocumentSectionTypePageFooter == 4, "PageFooter is 4");
	MAD_PASS(MADDocumentSectionTypeBody == 5, "Body is 5");
	MAD_PASS(MADDocumentSectionTypeGroupHeader == 6, "GroupHeader is 6");
	MAD_PASS(MADDocumentSectionTypeGroupFooter == 7, "GroupFooter is 7");
}

static void testSectionRepresentationThreeArgConstructor(void) {
	MADSectionRepresentation *section = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeBody
																				groupLevel:2
																					   row:42];
	MAD_PASS(section.sectionType == MADDocumentSectionTypeBody, "the section type");
	MAD_PASS(section.groupLevel == (NSUInteger)2, "the group level");
	MAD_PASS(section.detailRowId == (NSUInteger)42, "the detail row");
}

static void testSectionRepresentationTwoArgConstructor(void) {
	MADSectionRepresentation *section = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeReportHeader
																					   row:7];
	MAD_PASS(section.sectionType == MADDocumentSectionTypeReportHeader, "the section type");
	MAD_PASS(section.groupLevel == NSUIntegerMax, "no group level is NSUIntegerMax");
	MAD_PASS(section.detailRowId == (NSUInteger)7, "the detail row");
}

static void testSectionRepresentationCopy(void) {
	MADSectionRepresentation *original = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeGroupHeader
																				  groupLevel:3
																						 row:99];
	MADSectionRepresentation *copy = [original copy];
	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS(copy.sectionType == original.sectionType, "the copy's section type");
	MAD_PASS(copy.groupLevel == original.groupLevel, "the copy's group level");
	MAD_PASS(copy.detailRowId == original.detailRowId, "the copy's detail row");
}

static void testSectionRepresentationSecureCodingRoundTrip(void) {
	MADSectionRepresentation *original = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeGroupHeader
																				  groupLevel:3
																						 row:99];

	NSError *error = nil;
#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original requiringSecureCoding:YES error:&error];
	MAD_PASS(error == nil, "no error from the secure archive");
	MAD_PASS(data != nil, "the secure archive has bytes");

	MADSectionRepresentation *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADSectionRepresentation class]
																		  fromData:data
																			 error:&error];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original requiringSecureCoding:NO error:&error];
	MAD_PASS(error == nil, "no error from the archive");
	MAD_PASS(data != nil, "the archive has bytes");

	MADSectionRepresentation *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
#endif
	MAD_PASS(error == nil, "no error from unarchiving");
	MAD_PASS(decoded != nil, "the section representation round trips");
	MAD_PASS(decoded.sectionType == MADDocumentSectionTypeGroupHeader, "the section type survives the round trip");
	MAD_PASS(decoded.groupLevel == (NSUInteger)3, "the group level survives the round trip");
	MAD_PASS(decoded.detailRowId == (NSUInteger)99, "the detail row survives the round trip");
}

#pragma mark - MADTableFieldIdentifier

static void testTableFieldIdentifier(void) {
	MADTableFieldIdentifier *identifier = [[MADTableFieldIdentifier alloc] initWithTableID:10 andFieldID:20];
	MAD_PASS(identifier.tableID == (int64_t)10, "the table id");
	MAD_PASS(identifier.fieldID == (int64_t)20, "the field id");
	MAD_PASS_EQUAL(identifier.tableObjectID, @10, "the table object id");
	MAD_PASS_EQUAL(identifier.fieldObjectID, @20, "the field object id");
}

#pragma mark - NSPredicate+Creators

static void testPredicateWithIdentifier(void) {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:5];
	NSString *expected = [[NSString alloc] initWithFormat:@"identifier %@ 5", MADPredicateFormatEqual];
	MAD_PASS_EQUAL(predicate.predicateFormat, expected, "the identifier predicate format");
}

static void testPredicateWithIdentifierAtKeyPath(void) {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:5 atKeyPath:@"foo"];
	NSString *expected = [[NSString alloc] initWithFormat:@"foo %@ 5", MADPredicateFormatEqual];
	MAD_PASS_EQUAL(predicate.predicateFormat, expected, "the key-path predicate format");
}

static void testPredicateWithNumberAndExpression(void) {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithNumber:@5
														andExpression:[NSExpression expressionForKeyPath:@"bar"]];
	NSString *expected = [[NSString alloc] initWithFormat:@"bar %@ 5", MADPredicateFormatEqual];
	MAD_PASS_EQUAL(predicate.predicateFormat, expected, "the expression predicate format");
}

static void testPredicatePropertyNotNull(void) {
	NSPredicate *predicate = [NSPredicate newPredicateProperyNotNull:@"name"];
	NSString *expected = [[NSString alloc] initWithFormat:@"name != %@", MADPredicateFormatNil];
	MAD_PASS_EQUAL(predicate.predicateFormat, expected, "the not-null predicate format");
}

#pragma mark - Enum / string-constant value contracts

static void testPredicateOperatorEnumValues(void) {
	MAD_PASS(MADPredicateOperatorEqual == 0, "Equal is 0");
	MAD_PASS(MADPredicateOperatorNotEqual == 1, "NotEqual is 1");
	MAD_PASS(MADPredicateOperatorGreaterThan == 2, "GreaterThan is 2");
	MAD_PASS(MADPredicateOperatorGreaterThanOrEqualTo == 3, "GreaterThanOrEqualTo is 3");
	MAD_PASS(MADPredicateOperatorLessThan == 4, "LessThan is 4");
	MAD_PASS(MADPredicateOperatorLessThanOrEqualTo == 5, "LessThanOrEqualTo is 5");
}

static void testSortOrderEnumValues(void) {
	MAD_PASS(MADSortOrderAccending == 0, "Accending is 0");
	MAD_PASS(MADSortOrderDecending == 1, "Decending is 1");
}

static void testQueryLinkTypeEnumValues(void) {
	MAD_PASS(MADLinkTypeInnerJoin == 0, "InnerJoin is 0");
	MAD_PASS(MADLinkTypeEquiJoin == 1, "EquiJoin is 1");
	MAD_PASS(MADLinkTypeNaturalJoin == 2, "NaturalJoin is 2");
	MAD_PASS(MADLinkTypeCrossJoin == 3, "CrossJoin is 3");
	MAD_PASS(MADLinkTypeLeftOuterJoin == 4, "LeftOuterJoin is 4");
	MAD_PASS(MADLinkTypeRightOuterJoin == 5, "RightOuterJoin is 5");
	MAD_PASS(MADLinkTypeFullOuterJoin == 6, "FullOuterJoin is 6");
	MAD_PASS(MADLinkTypeUnknown == 7, "Unknown is 7");
}

static void testSQLJoinTypeStringConstants(void) {
	MAD_PASS_EQUAL(MNSJoinTypeInnerJoin, @"MNSJoinTypeInnerJoin", "the inner join constant");
	MAD_PASS_EQUAL(MNSJoinTypeEquiJoin, @"MNSJoinTypeEquiJoin", "the equi join constant");
	MAD_PASS_EQUAL(MNSJoinTypeNaturalJoin, @"MNSJoinTypeNaturalJoin", "the natural join constant");
	MAD_PASS_EQUAL(MNSJoinTypeCrossJoin, @"MNSJoinTypeCrossJoin", "the cross join constant");
	MAD_PASS_EQUAL(MNSJoinTypeLeftOuterJoin, @"MNSJoinTypeLeftOuterJoin", "the left outer join constant");
	MAD_PASS_EQUAL(MNSJoinTypeRightOuterJoin, @"MNSJoinTypeRightOuterJoin", "the right outer join constant");
	MAD_PASS_EQUAL(MNSJoinTypeFullOuterJoin, @"MNSJoinTypeFullOuterJoin", "the full outer join constant");
}

#pragma mark - MADQueryCacheSelectGroupKeys

// The parameters as -[MADQuery queryWithType:parameters:] passes them, which is where
// this query is built.  The dictionary is assembled in this helper rather than inline
// in each test: an @{} literal carries commas, which do not survive a macro argument.
static MADQueryCacheSelectGroupKeys *groupKeysQueryWithPredicates(NSArray <NSDictionary *> *predicates) {

	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier: @"Customer.City"];
	column.type = MADDataTypeString;
	column.nativeType = MADDataTypeString;

	NSDictionary *parameters = @{
		@(MADQuerySelectTableName)		: @"Customer",
		@(MADQuerySelectFieldKeys)		: @[@"Customer.City"],
		@(MADQuerySelectSortAccending)	: @YES,
		@(MADQuerySelectColumns)		: @{ @"Customer.City" : column },
		@(MADQuerySelectPredicates)		: predicates ?: @[]
	};

	return [[MADQueryCacheSelectGroupKeys alloc] initWithObject: parameters];
}

static NSDictionary *predicateOnCity(id value) {
	return @{ MADQueryKeyPredicateColumn: @"Customer.City",
			  MADQueryKeyPredicateValue:  value };
}

// The defect this pins: the value was written as @"%@ = \"%@\"", and a SQL reader takes a
// double-quoted token for a *name*.  The filter therefore asked for a column called
// London.  Sqlite3 only forgave that while SQLITE_DQS was on, and that is now off.
static void testGroupKeysQuotesTheValueAsALiteralNotAsAName(void) {

	NSArray *predicates = @[predicateOnCity(@"London")];
	MADQueryCacheSelectGroupKeys *query = groupKeysQueryWithPredicates(predicates);
	NSString *sql = [query getSql: nil];

	NSString *asName = @"= \"London\"";
	NSString *asLiteral = @"= 'London'";

	MAD_PASS(sql != nil, "the group-keys query built SQL");
	MAD_PASS(![sql containsString: asName],
			 "The value is still quoted as a name: %s", sql.UTF8String);
	MAD_PASS([sql containsString: asLiteral],
			 "Expected a quoted literal in: %s", sql.UTF8String);
}

// The names are identifiers and stay in double quotes; what changed is only the value.
static void testGroupKeysQuotesColumnAndTableAsIdentifiers(void) {

	NSArray *predicates = @[predicateOnCity(@"London")];
	MADQueryCacheSelectGroupKeys *query = groupKeysQueryWithPredicates(predicates);
	NSString *sql = [query getSql: nil];

	MAD_PASS([sql containsString: @"FROM \"Customer\""], "the table is a double-quoted identifier: %s", sql.UTF8String);
	MAD_PASS([sql containsString: @"\"Customer.City\" = 'London'"],
			 "the column is an identifier and the value a literal: %s", sql.UTF8String);
}

// A statement with no predicates used to read "SELECT DISTINCT ... FROM \"Customer\"  WHERE
// ORDER BY ...", which is a syntax error.  There is simply no clause now.
static void testGroupKeysWithoutPredicatesLeavesOutTheWhereClause(void) {

	MADQueryCacheSelectGroupKeys *query = groupKeysQueryWithPredicates(@[]);
	NSString *sql = [query getSql: nil];

	MAD_PASS(![sql containsString: @"WHERE"], "the statement still has a WHERE clause: %s", sql.UTF8String);
	MAD_PASS([sql containsString: @"ORDER BY"], "the statement has an ORDER BY clause: %s", sql.UTF8String);
}

// A NULL term is a SQL keyword, not a string, and must not be quoted.
static void testGroupKeysWritesNullAsAKeyword(void) {

	NSArray *predicates = @[predicateOnCity([NSNull null])];
	MADQueryCacheSelectGroupKeys *query = groupKeysQueryWithPredicates(predicates);
	NSString *sql = [query getSql: nil];

	MAD_PASS([sql containsString: @"\"Customer.City\" = NULL"], "NULL is written as a keyword: %s", sql.UTF8String);
}

// An apostrophe inside the value is escaped by the dialect, not left to end the literal.
static void testGroupKeysEscapesAnApostropheInTheValue(void) {

	NSArray *predicates = @[predicateOnCity(@"O'Brien")];
	MADQueryCacheSelectGroupKeys *query = groupKeysQueryWithPredicates(predicates);
	NSString *sql = [query getSql: nil];

	MAD_PASS([sql containsString: @"= 'O''Brien'"], "the apostrophe is doubled: %s", sql.UTF8String);
}

MAD_TEST_MAIN("MADCoreLogicTests",
	MAD_TEST(testDigitCountRecurInt),
	MAD_TEST(testDigitCountRecurIntNegative),
	MAD_TEST(testDigitCountRecurIntBounds),
	MAD_TEST(testDigitCountRecurUint),
	MAD_TEST(testDigitCountIterativeInt),
	MAD_TEST(testDigitCountIterativeIntBounds),
	MAD_TEST(testDigitCountIterativeUint),
	MAD_TEST(testAbsoluteValueFunctions),
	MAD_TEST(testHorizontalAlignmentEnumValues),
	MAD_TEST(testVerticalAlignmentEnumValues),
	MAD_TEST(testAlignmentMakeAndMake64),
	MAD_TEST(testAlignmentClass),
	MAD_TEST(testDocumentSectionTypeEnumValues),
	MAD_TEST(testSectionRepresentationThreeArgConstructor),
	MAD_TEST(testSectionRepresentationTwoArgConstructor),
	MAD_TEST(testSectionRepresentationCopy),
	MAD_TEST(testSectionRepresentationSecureCodingRoundTrip),
	MAD_TEST(testTableFieldIdentifier),
	MAD_TEST(testPredicateWithIdentifier),
	MAD_TEST(testPredicateWithIdentifierAtKeyPath),
	MAD_TEST(testPredicateWithNumberAndExpression),
	MAD_TEST(testPredicatePropertyNotNull),
	MAD_TEST(testPredicateOperatorEnumValues),
	MAD_TEST(testSortOrderEnumValues),
	MAD_TEST(testQueryLinkTypeEnumValues),
	MAD_TEST(testSQLJoinTypeStringConstants),
	MAD_TEST(testGroupKeysQuotesTheValueAsALiteralNotAsAName),
	MAD_TEST(testGroupKeysQuotesColumnAndTableAsIdentifiers),
	MAD_TEST(testGroupKeysWithoutPredicatesLeavesOutTheWhereClause),
	MAD_TEST(testGroupKeysWritesNullAsAKeyword),
	MAD_TEST(testGroupKeysEscapesAnApostropheInTheValue));
