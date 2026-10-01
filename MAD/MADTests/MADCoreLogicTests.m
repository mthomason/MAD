//
//  MADCoreLogicTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 1 (pure-logic / value-type) coverage for the MAD framework.  These types
//  carry no Core Data or database state, so they can be exercised directly:
//    * madmath C helpers (digit counting, absolute value).
//    * MADAlignment (MADAlignmentMake / MADAlignmentMake64 + the class).
//    * MADSectionRepresentation (constructors, copy, secure coding round-trip).
//    * MADTableFieldIdentifier / MADTableFieldReference.
//    * NSPredicate+Creators (predicate builders).
//    * Enum + string-constant value contracts (MADPredicateOperator, MADSortOrder,
//      MADQueryLinkType, MADSQLJoinType, MADocumentSectionType).
//

#import <XCTest/XCTest.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#include <limits.h>

#import "madmath.h"
#import "MADAlignment.h"
#import "MADSectionRepresentation.h"
#import "MADTableFieldIdentifier.h"
#import "NSPredicate+Creators.h"
#import "MADPredicateOperator.h"
#import "MADSortOrder.h"
#import "MADSQLJoinType.h"
#import "MADQueryLinkType.h"
#import "MADocumentSectionType.h"

@interface MADCoreLogicTests : XCTestCase
@end

@implementation MADCoreLogicTests

#pragma mark - madmath

- (void)testDigitCountRecurInt {
	XCTAssertEqual(digit_count_recur_int(0), 1);
	XCTAssertEqual(digit_count_recur_int(5), 1);
	XCTAssertEqual(digit_count_recur_int(9), 1);
	XCTAssertEqual(digit_count_recur_int(10), 2);
	XCTAssertEqual(digit_count_recur_int(99), 2);
	XCTAssertEqual(digit_count_recur_int(100), 3);
	XCTAssertEqual(digit_count_recur_int(123456), 6);
}

- (void)testDigitCountRecurIntNegative {
	XCTAssertEqual(digit_count_recur_int(-1), 1);
	XCTAssertEqual(digit_count_recur_int(-9), 1);
	XCTAssertEqual(digit_count_recur_int(-10), 2);
	XCTAssertEqual(digit_count_recur_int(-123456), 6);
}

- (void)testDigitCountRecurIntBounds {
	XCTAssertEqual(digit_count_recur_int(INT_MAX), 10);
	// INT_MIN is collapsed onto INT_MAX before counting (implementation quirk).
	XCTAssertEqual(digit_count_recur_int(INT_MIN), 10);
}

- (void)testDigitCountRecurUInt {
	XCTAssertEqual(digit_count_recur_uint(0), 1);
	XCTAssertEqual(digit_count_recur_uint(9), 1);
	XCTAssertEqual(digit_count_recur_uint(10), 2);
	XCTAssertEqual(digit_count_recur_uint(UINT_MAX), 10);
}

- (void)testDigitCountIterativeInt {
	XCTAssertEqual(digit_count_iterative_int(0), 1);
	XCTAssertEqual(digit_count_iterative_int(9), 1);
	XCTAssertEqual(digit_count_iterative_int(10), 2);
	XCTAssertEqual(digit_count_iterative_int(-10), 2);
	XCTAssertEqual(digit_count_iterative_int(123456), 6);
	XCTAssertEqual(digit_count_iterative_int(-123456), 6);
}

- (void)testDigitCountIterativeIntBounds {
	XCTAssertEqual(digit_count_iterative_int(INT_MAX), 10);
	// INT_MIN is collapsed onto INT_MAX before counting (implementation quirk).
	XCTAssertEqual(digit_count_iterative_int(INT_MIN), 10);
}

- (void)testDigitCountIterativeUInt {
	XCTAssertEqual(digit_count_iterative_uint(0), 1);
	XCTAssertEqual(digit_count_iterative_uint(9), 1);
	XCTAssertEqual(digit_count_iterative_uint(10), 2);
	XCTAssertEqual(digit_count_iterative_uint(UINT_MAX), 10);
}

- (void)testAbsoluteValueFunctions {
	XCTAssertEqual(i32abs(0), 0);
	XCTAssertEqual(i32abs(5), 5);
	XCTAssertEqual(i32abs(-5), 5);

	XCTAssertEqual(i64abs(0), 0);
	XCTAssertEqual(i64abs(123), 123);
	XCTAssertEqual(i64abs(-123), 123);
}

#pragma mark - MADAlignment

- (void)testHorizontalAlignmentEnumValues {
	XCTAssertEqual(MADHorizontalAlignmentUnknown, -1);
	XCTAssertEqual(MADHorizontalAlignmentLeft, 0);
	XCTAssertEqual(MADHorizontalAlignmentCenter, 1);
	XCTAssertEqual(MADHorizontalAlignmentRight, 2);
	XCTAssertEqual(MADHorizontalAlignmentJustified, 3);
	XCTAssertEqual(MADHorizontalAlignmentNatrual, 4);
}

- (void)testVerticalAlignmentEnumValues {
	XCTAssertEqual(MADVerticalAlignmentUnknown, -1);
	XCTAssertEqual(MADVerticalAlignmentTop, 0);
	XCTAssertEqual(MADVerticalAlignmentCenter, 1);
	XCTAssertEqual(MADVerticalAlignmentBottom, 2);
}

- (void)testAlignmentMakeAndMake64 {
	MADAlignment_t a = MADAlignmentMake(MADHorizontalAlignmentCenter, MADVerticalAlignmentBottom);
	XCTAssertEqual(a.horizontal, MADHorizontalAlignmentCenter);
	XCTAssertEqual(a.vertical, MADVerticalAlignmentBottom);

	// MADAlignmentMake64 maps each valid raw value straight through.
	MADAlignment_t b = MADAlignmentMake64(MADHorizontalAlignmentJustified, MADVerticalAlignmentCenter);
	XCTAssertEqual(b.horizontal, MADHorizontalAlignmentJustified);
	XCTAssertEqual(b.vertical, MADVerticalAlignmentCenter);

	// Unknown raw values fall back to Left / Top.
	MADAlignment_t c = MADAlignmentMake64(999, 999);
	XCTAssertEqual(c.horizontal, MADHorizontalAlignmentLeft);
	XCTAssertEqual(c.vertical, MADVerticalAlignmentTop);
}

- (void)testAlignmentClass {
	MADAlignment *alignment = [[MADAlignment alloc] initWithHorizontal:MADHorizontalAlignmentLeft
															  vertical:MADVerticalAlignmentTop];
	XCTAssertEqual(alignment.horizontal, MADHorizontalAlignmentLeft);
	XCTAssertEqual(alignment.vertical, MADVerticalAlignmentTop);

	alignment.horizontal = MADHorizontalAlignmentRight;
	alignment.vertical = MADVerticalAlignmentBottom;
	XCTAssertEqual(alignment.horizontal, MADHorizontalAlignmentRight);
	XCTAssertEqual(alignment.vertical, MADVerticalAlignmentBottom);
}

#pragma mark - MADSectionRepresentation / MADocumentSectionType

- (void)testDocumentSectionTypeEnumValues {
	XCTAssertEqual(MADDocumentSectionTypeUnknown, 0);
	XCTAssertEqual(MADDocumentSectionTypeReportHeader, 1);
	XCTAssertEqual(MADDocumentSectionTypeReportFooter, 2);
	XCTAssertEqual(MADDocumentSectionTypePageHeader, 3);
	XCTAssertEqual(MADDocumentSectionTypePageFooter, 4);
	XCTAssertEqual(MADDocumentSectionTypeBody, 5);
	XCTAssertEqual(MADDocumentSectionTypeGroupHeader, 6);
	XCTAssertEqual(MADDocumentSectionTypeGroupFooter, 7);
}

- (void)testSectionRepresentationThreeArgConstructor {
	MADSectionRepresentation *section = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeBody
																				groupLevel:2
																					   row:42];
	XCTAssertEqual(section.sectionType, MADDocumentSectionTypeBody);
	XCTAssertEqual(section.groupLevel, (NSUInteger)2);
	XCTAssertEqual(section.detailRowId, (NSUInteger)42);
}

- (void)testSectionRepresentationTwoArgConstructor {
	MADSectionRepresentation *section = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeReportHeader
																					   row:7];
	XCTAssertEqual(section.sectionType, MADDocumentSectionTypeReportHeader);
	XCTAssertEqual(section.groupLevel, NSUIntegerMax);
	XCTAssertEqual(section.detailRowId, (NSUInteger)7);
}

- (void)testSectionRepresentationCopy {
	MADSectionRepresentation *original = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeGroupHeader
																				  groupLevel:3
																						 row:99];
	MADSectionRepresentation *copy = [original copy];
	XCTAssertNotNil(copy);
	XCTAssertEqual(copy.sectionType, original.sectionType);
	XCTAssertEqual(copy.groupLevel, original.groupLevel);
	XCTAssertEqual(copy.detailRowId, original.detailRowId);
}

- (void)testSectionRepresentationSecureCodingRoundTrip {
	MADSectionRepresentation *original = [MADSectionRepresentation newSectionRepresentation:MADDocumentSectionTypeGroupHeader
																				  groupLevel:3
																						 row:99];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADSectionRepresentation *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADSectionRepresentation class]
																		  fromData:data
																			 error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.sectionType, MADDocumentSectionTypeGroupHeader);
	XCTAssertEqual(decoded.groupLevel, (NSUInteger)3);
	XCTAssertEqual(decoded.detailRowId, (NSUInteger)99);
}

#pragma mark - MADTableFieldIdentifier / MADTableFieldReference

- (void)testTableFieldIdentifier {
	MADTableFieldIdentifier *identifier = [[MADTableFieldIdentifier alloc] initWithTableID:10 andFieldID:20];
	XCTAssertEqual(identifier.tableID, (int64_t)10);
	XCTAssertEqual(identifier.fieldID, (int64_t)20);
	XCTAssertEqualObjects(identifier.tableObjectID, @10);
	XCTAssertEqualObjects(identifier.fieldObjectID, @20);
}

- (void)testTableFieldReferenceAcceptsNil {
	MADTableFieldReference *reference = [[MADTableFieldReference alloc] initWithTableID:nil andFieldID:nil];
	XCTAssertNil(reference.tableID);
	XCTAssertNil(reference.fieldID);
}

#pragma mark - NSPredicate+Creators

- (void)testPredicateWithIdentifier {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:5];
	XCTAssertEqualObjects(predicate.predicateFormat, @"identifier == 5");
}

- (void)testPredicateWithIdentifierAtKeyPath {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:5 atKeyPath:@"foo"];
	XCTAssertEqualObjects(predicate.predicateFormat, @"foo == 5");
}

- (void)testPredicateWithNumberAndExpression {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithNumber:@5
														 andExpression:[NSExpression expressionForKeyPath:@"bar"]];
	XCTAssertEqualObjects(predicate.predicateFormat, @"bar == 5");
}

- (void)testPredicatePropertyNotNull {
	NSPredicate *predicate = [NSPredicate newPredicateProperyNotNull:@"name"];
	XCTAssertEqualObjects(predicate.predicateFormat, @"name != nil");
}

- (void)testPredicateWithObjectID {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID:nil];
	XCTAssertTrue([predicate isKindOfClass:[NSComparisonPredicate class]]);
	NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
	XCTAssertEqual(comparison.predicateOperatorType, NSEqualToPredicateOperatorType);
	XCTAssertEqual(comparison.leftExpression.expressionType, NSEvaluatedObjectExpressionType);
	XCTAssertEqual(comparison.rightExpression.expressionType, NSConstantValueExpressionType);
}

- (void)testPredicateWithObjectIDAtKeyPath {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID:nil atKeyPath:@"foo"];
	XCTAssertTrue([predicate isKindOfClass:[NSComparisonPredicate class]]);
	NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
	XCTAssertEqual(comparison.predicateOperatorType, NSEqualToPredicateOperatorType);
	// The keyPath is captured as a constant, not as a key-path expression.
	XCTAssertEqual(comparison.leftExpression.expressionType, NSConstantValueExpressionType);
	XCTAssertEqualObjects(comparison.leftExpression.constantValue, @"foo");
	XCTAssertEqual(comparison.rightExpression.expressionType, NSConstantValueExpressionType);
}

#pragma mark - Enum / string-constant value contracts

- (void)testPredicateOperatorEnumValues {
	XCTAssertEqual(MADPredicateOperatorEqual, 0);
	XCTAssertEqual(MADPredicateOperatorNotEqual, 1);
	XCTAssertEqual(MADPredicateOperatorGreaterThan, 2);
	XCTAssertEqual(MADPredicateOperatorGreaterThanOrEqualTo, 3);
	XCTAssertEqual(MADPredicateOperatorLessThan, 4);
	XCTAssertEqual(MADPredicateOperatorLessThanOrEqualTo, 5);
}

- (void)testSortOrderEnumValues {
	XCTAssertEqual(MADSortOrderAccending, 0);
	XCTAssertEqual(MADSortOrderDecending, 1);
}

- (void)testQueryLinkTypeEnumValues {
	XCTAssertEqual(MADLinkTypeInnerJoin, 0);
	XCTAssertEqual(MADLinkTypeEquiJoin, 1);
	XCTAssertEqual(MADLinkTypeNaturalJoin, 2);
	XCTAssertEqual(MADLinkTypeCrossJoin, 3);
	XCTAssertEqual(MADLinkTypeLeftOuterJoin, 4);
	XCTAssertEqual(MADLinkTypeRightOuterJoin, 5);
	XCTAssertEqual(MADLinkTypeFullOuterJoin, 6);
	XCTAssertEqual(MADLinkTypeUnknown, 7);
}

- (void)testSQLJoinTypeStringConstants {
	XCTAssertEqualObjects(MNSJoinTypeInnerJoin, @"MNSJoinTypeInnerJoin");
	XCTAssertEqualObjects(MNSJoinTypeEquiJoin, @"MNSJoinTypeEquiJoin");
	XCTAssertEqualObjects(MNSJoinTypeNaturalJoin, @"MNSJoinTypeNaturalJoin");
	XCTAssertEqualObjects(MNSJoinTypeCrossJoin, @"MNSJoinTypeCrossJoin");
	XCTAssertEqualObjects(MNSJoinTypeLeftOuterJoin, @"MNSJoinTypeLeftOuterJoin");
	XCTAssertEqualObjects(MNSJoinTypeRightOuterJoin, @"MNSJoinTypeRightOuterJoin");
	XCTAssertEqualObjects(MNSJoinTypeFullOuterJoin, @"MNSJoinTypeFullOuterJoin");
}

@end
