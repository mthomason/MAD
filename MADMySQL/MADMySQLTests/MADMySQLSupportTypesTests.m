//
//  MADMySQLSupportTypesTests.m
//  MADMySQLTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Offline coverage for the two small carrier types in MADMySQL: MADMySQLIndex,
//  which only remembers the connection it was built with, and MADMySQLLiteral,
//  the string wrapper the driver hands back for quoted literals.
//

#import <XCTest/XCTest.h>

#import "MADMySQLIndex.h"
#import "MADMySQLLiteral.h"
#import "MADMySQLConnection.h"

@interface MADMySQLSupportTypesTests : XCTestCase
@end

@implementation MADMySQLSupportTypesTests

- (MADMySQLConnection *)connectionWithoutAServer {
	return [[MADMySQLConnection alloc] init];
}

#pragma mark - MADMySQLIndex

- (void)testIndexFactoryKeepsTheConnection {
	MADMySQLConnection *connection = [self connectionWithoutAServer];

	MADMySQLIndex *index = [MADMySQLIndex indexWithConnection:connection];

	XCTAssertNotNil(index);
	XCTAssertEqual(index.connection, connection);
}

- (void)testIndexAcceptsANilConnection {
	MADMySQLIndex *index = [MADMySQLIndex indexWithConnection:nil];

	XCTAssertNotNil(index);
	XCTAssertNil(index.connection);
}

#pragma mark - MADMySQLLiteral

- (void)testLiteralCopiesItsString {
	NSMutableString *source = [NSMutableString stringWithString:@"O'Brien"];
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:source];

	[source appendString:@" and more"];

	// The literal took a copy: the caller's later edits do not show up.
	XCTAssertEqualObjects(literal.string, @"O'Brien");
}

- (void)testLiteralWithNilStringAnswersNil {
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:nil];

	XCTAssertNotNil(literal);
	XCTAssertNil(literal.string);
}

- (void)testLiteralWithAnEmptyStringIsEmpty {
	MADMySQLLiteral *literal = [MADMySQLLiteral literalWithString:@""];

	XCTAssertEqualObjects(literal.string, @"");
}

@end
