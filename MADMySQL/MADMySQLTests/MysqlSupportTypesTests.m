//
//  MysqlSupportTypesTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for the two small carrier types in MADMySQL: MysqlIndex,
//  which only remembers the connection it was built with, and MysqlLiteral,
//  the string wrapper the driver hands back for quoted literals.
//

#import <XCTest/XCTest.h>

#import "MysqlIndex.h"
#import "MysqlLiteral.h"
#import "MysqlConnection.h"

@interface MysqlSupportTypesTests : XCTestCase
@end

@implementation MysqlSupportTypesTests

- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

#pragma mark - MysqlIndex

- (void)testIndexFactoryKeepsTheConnection {
	MysqlConnection *connection = [self connectionWithoutAServer];

	MysqlIndex *index = [MysqlIndex indexWithConnection:connection];

	XCTAssertNotNil(index);
	XCTAssertEqual(index.connection, connection);
}

- (void)testIndexAcceptsANilConnection {
	MysqlIndex *index = [MysqlIndex indexWithConnection:nil];

	XCTAssertNotNil(index);
	XCTAssertNil(index.connection);
}

#pragma mark - MysqlLiteral

- (void)testLiteralCopiesItsString {
	NSMutableString *source = [NSMutableString stringWithString:@"O'Brien"];
	MysqlLiteral *literal = [MysqlLiteral literalWithString:source];

	[source appendString:@" and more"];

	// The literal took a copy: the caller's later edits do not show up.
	XCTAssertEqualObjects(literal.string, @"O'Brien");
}

- (void)testLiteralWithNilStringAnswersNil {
	MysqlLiteral *literal = [MysqlLiteral literalWithString:nil];

	XCTAssertNotNil(literal);
	XCTAssertNil(literal.string);
}

- (void)testLiteralWithAnEmptyStringIsEmpty {
	MysqlLiteral *literal = [MysqlLiteral literalWithString:@""];

	XCTAssertEqualObjects(literal.string, @"");
}

@end
