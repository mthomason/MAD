//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportSectionRepresentationTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADReportSectionRepresentationTests.m: the two
//  section-representation containers -- a set of MADReportLineRepresentation
//  objects in reading order, and the list of those row containers.  Also pins
//  the count-accessor mismatch on the rows container: the header declares
//  `itemCount`, but the implementation names the getter `isItemCount`, so the
//  declared accessor reads the auto-synthesised zero.  See docs/project/BUGS.md.
//

#import "MADTestSupport.h"

#import <MAD/MADReportLineRepresentation.h>
#import <MAD/MADReportSectionRowsRepresentation.h>
#import <MAD/MADReportSectionRepresentation.h>

// -isItemCount is implemented but declared nowhere public; this test-only category is
// the deliberate bridge.
@interface MADReportSectionRowsRepresentation (TestCount)
- (NSUInteger)isItemCount;
@end

#pragma mark - Fixtures

static MADReportLineRepresentation *lineWithText(NSString *text, CGFloat x, CGFloat y) {
	return [[MADReportLineRepresentation alloc] initWithObject:text
														  type:MADPrintPageElementTypeLabelStatic
														 frame:CGRectMake(x, y, 10, 10)];
}

#pragma mark - MADReportSectionRowsRepresentation

static void testDeclaredItemCountGetterReadsZero(void) {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:2];
	[rows addLine:lineWithText(@"a", 0, 0)];
	[rows addLine:lineWithText(@"b", 0, 20)];

	// Characterization of the accessor mismatch: the declared property is synthesised
	// and never written, so it reads zero no matter how many lines the container holds.
	MAD_PASS([rows itemCount] == (NSUInteger)0, "the declared itemCount reads the synthesised zero");
	// The implemented getter, reached through the test-only bridge, is the real count.
	MAD_PASS([rows isItemCount] == (NSUInteger)2, "the implemented isItemCount is the real count");
}

static void testAllLinesAreSortedByFrame(void) {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:3];
	MADReportLineRepresentation *last = lineWithText(@"last", 50, 20);
	MADReportLineRepresentation *second = lineWithText(@"second", 10, 10);
	MADReportLineRepresentation *first = lineWithText(@"first", 5, 10);

	// Added out of order on purpose.
	[rows addLine:last];
	[rows addLine:second];
	[rows addLine:first];

	NSArray<MADReportLineRepresentation *> *lines = [rows allLines];
	MAD_PASS(lines.count == (NSUInteger)3, "all three lines are held");
	MAD_PASS_EQUAL(lines[0].label, @"first", "the first line sorts first");
	MAD_PASS_EQUAL(lines[1].label, @"second", "the second line sorts second");
	MAD_PASS_EQUAL(lines[2].label, @"last", "the last line sorts last");
}

static void testLinesBehaveAsASet(void) {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	MADReportLineRepresentation *line = lineWithText(@"once", 0, 0);

	[rows addLine:line];
	[rows addLine:line];

	MAD_PASS([rows allLines].count == (NSUInteger)1, "a repeated line is held once");
	MAD_PASS([rows isItemCount] == (NSUInteger)1, "the implemented count agrees");
}

static void testCharacterAndElementCounts(void) {
	MADReportSectionRowsRepresentation *rows = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:2];
	[rows addLine:lineWithText(@"ab", 0, 0)];
	[rows addLine:lineWithText(@"cde", 0, 20)];

	MAD_PASS([rows characterCount] == (NSUInteger)5, "the character count sums the lines");
	MAD_PASS([rows elementCount] == (NSUInteger)2, "the element count counts the lines");
}

#pragma mark - MADReportSectionRepresentation

static void testSectionDefaults(void) {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:0];

	MAD_PASS(section.numberOfRows == (NSUInteger)0, "a fresh section has no rows");
	MAD_PASS(!section.isVisibile, "a fresh section is not visible");
	MAD_PASS(section.type == MADDocumentSectionTypeUnknown, "a fresh section's type is unknown");
}

static void testAddRowCountsAndAggregates(void) {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:2];

	MADReportSectionRowsRepresentation *first = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	[first addLine:lineWithText(@"abc", 0, 0)];
	MADReportSectionRowsRepresentation *second = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:1];
	[second addLine:lineWithText(@"de", 0, 0)];

	MAD_PASS([section addRow:first error:NULL], "the first row adds");
	MAD_PASS([section addRow:second error:NULL], "the second row adds");

	MAD_PASS(section.numberOfRows == (NSUInteger)2, "the rows are counted");
	MAD_PASS([section characterCount] == (NSUInteger)5, "the character count aggregates over the rows");
	MAD_PASS([section elementCount] == (NSUInteger)2, "the element count aggregates over the rows");
}

static void testAddNilRowReportsError(void) {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:1];

	NSError *error = nil;
	bool success = [section addRow:(MADReportSectionRowsRepresentation *)nil error:&error];

	MAD_PASS(!success, "adding a nil row fails");
	MAD_PASS(error != nil, "adding a nil row reports an error");
	MAD_PASS(error.code == 49832, "the error code");
	MAD_PASS_EQUAL(error.domain, @"MADReportSectionRepresentation", "the error domain is the class name");
	MAD_PASS_EQUAL(error.localizedDescription, @"Failed to add null value.", "the error description");
	MAD_PASS(section.numberOfRows == (NSUInteger)0, "the failed add left no row");
}

static void testVisibilityAndTypeAreSettable(void) {
	MADReportSectionRepresentation *section = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:0];
	section.visibility = YES;
	section.type = MADDocumentSectionTypePageHeader;

	MAD_PASS(section.isVisibile, "the visibility setter round-trips");
	MAD_PASS(section.type == MADDocumentSectionTypePageHeader, "the type setter round-trips");
}

MAD_TEST_MAIN("MADReportSectionRepresentationTests",
	MAD_TEST(testDeclaredItemCountGetterReadsZero),
	MAD_TEST(testAllLinesAreSortedByFrame),
	MAD_TEST(testLinesBehaveAsASet),
	MAD_TEST(testCharacterAndElementCounts),
	MAD_TEST(testSectionDefaults),
	MAD_TEST(testAddRowCountsAndAggregates),
	MAD_TEST(testAddNilRowReportsError),
	MAD_TEST(testVisibilityAndTypeAreSettable));
