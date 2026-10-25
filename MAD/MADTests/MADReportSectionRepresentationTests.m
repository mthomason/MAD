//
//  MADReportSectionRepresentationTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 2 coverage for the two section-representation containers:
//
//    * MADReportSectionRowsRepresentation -- a set of MADReportLineRepresentation
//      objects, exposed in reading order and summarised by character/element counts.
//    * MADReportSectionRepresentation -- a list of those row containers.
//
//  Also pins the count-accessor mismatch on the rows container: the header declares
//  `itemCount`, but the implementation names the getter `isItemCount`, so the declared
//  accessor reads the auto-synthesised zero.  See BUGS.md.
//

#import <XCTest/XCTest.h>

#import "MADReportLineRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import "MADReportSectionRepresentation.h"

// -isItemCount is implemented but declared nowhere public; this test-only category is
// the deliberate bridge.
@interface MADReportSectionRowsRepresentation (TestCount)
- (NSUInteger)isItemCount;
@end

@interface MADReportSectionRepresentationTests : XCTestCase
@end

@implementation MADReportSectionRepresentationTests

#pragma mark - Fixtures

- (MADReportLineRepresentation *)lineWithText:(NSString *)text x:(CGFloat)x y:(CGFloat)y {
	return [[MADReportLineRepresentation alloc] initWithObject:text
														  type:MADPrintPageElementTypeLabelStatic
														 frame:CGRectMake(x, y, 10, 10)];
}

#pragma mark - MADReportSectionRowsRepresentation

- (void)testDeclaredItemCountGetterReadsZero {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:2];
	[rows addLine:[self lineWithText:@"a" x:0 y:0]];
	[rows addLine:[self lineWithText:@"b" x:0 y:20]];

	// Characterization of the accessor mismatch: the declared property is synthesised
	// and never written, so it reads zero no matter how many lines the container holds.
	XCTAssertEqual([rows itemCount], (NSUInteger)0);
	// The implemented getter, reached through the test-only bridge, is the real count.
	XCTAssertEqual([rows isItemCount], (NSUInteger)2);
}

- (void)testAllLinesAreSortedByFrame {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:3];
	MADReportLineRepresentation *last = [self lineWithText:@"last" x:50 y:20];
	MADReportLineRepresentation *second = [self lineWithText:@"second" x:10 y:10];
	MADReportLineRepresentation *first = [self lineWithText:@"first" x:5 y:10];

	// Added out of order on purpose.
	[rows addLine:last];
	[rows addLine:second];
	[rows addLine:first];

	NSArray<MADReportLineRepresentation *> *lines = [rows allLines];
	XCTAssertEqual(lines.count, (NSUInteger)3);
	XCTAssertEqualObjects(lines[0].label, @"first");
	XCTAssertEqualObjects(lines[1].label, @"second");
	XCTAssertEqualObjects(lines[2].label, @"last");
}

- (void)testLinesBehaveAsASet {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	MADReportLineRepresentation *line = [self lineWithText:@"once" x:0 y:0];

	[rows addLine:line];
	[rows addLine:line];

	XCTAssertEqual([rows allLines].count, (NSUInteger)1);
	XCTAssertEqual([rows isItemCount], (NSUInteger)1);
}

- (void)testCharacterAndElementCounts {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:2];
	[rows addLine:[self lineWithText:@"ab" x:0 y:0]];
	[rows addLine:[self lineWithText:@"cde" x:0 y:20]];

	XCTAssertEqual([rows characterCount], (NSUInteger)5);
	XCTAssertEqual([rows elementCount], (NSUInteger)2);
}

#pragma mark - MADReportSectionRepresentation

- (void)testSectionDefaults {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:0];

	XCTAssertEqual(section.numberOfRows, (NSUInteger)0);
	XCTAssertFalse(section.isVisibile);
	XCTAssertEqual(section.type, MADDocumentSectionTypeUnknown);
}

- (void)testAddRowCountsAndAggregates {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:2];

	MADReportSectionRowsRepresentation *first = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	[first addLine:[self lineWithText:@"abc" x:0 y:0]];
	MADReportSectionRowsRepresentation *second = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	[second addLine:[self lineWithText:@"de" x:0 y:0]];

	XCTAssertTrue([section addRow:first error:NULL]);
	XCTAssertTrue([section addRow:second error:NULL]);

	XCTAssertEqual(section.numberOfRows, (NSUInteger)2);
	XCTAssertEqual([section characterCount], (NSUInteger)5);
	XCTAssertEqual([section elementCount], (NSUInteger)2);
}

- (void)testAddNilRowReportsError {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:1];

	NSError *error = nil;
	bool success = [section addRow:(MADReportSectionRowsRepresentation *)nil error:&error];

	XCTAssertFalse(success);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 49832);
	XCTAssertEqualObjects(error.domain, @"MADReportSectionRepresentation");
	XCTAssertEqualObjects(error.localizedDescription, @"Failed to add null value.");
	XCTAssertEqual(section.numberOfRows, (NSUInteger)0);
}

- (void)testVisibilityAndTypeAreSettable {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:0];
	section.visibility = YES;
	section.type = MADDocumentSectionTypePageHeader;

	XCTAssertTrue(section.isVisibile);
	XCTAssertEqual(section.type, MADDocumentSectionTypePageHeader);
}

@end
