//
//  MADRptqDocumentSectionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADRptqDocumentSectionTests.m: the pure-logic
//  RptqDocumentSection "Extras" category -- section-type mapping by row/group,
//  key-path constants, form-feed wrapping style, and the localized display
//  name.  The store the Xcode suite borrows from Core Data is a real SQLite
//  file under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/RptqDocumentSection.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionWrappingStyle.h>
#import <MAD/MADocumentSectionType.h>

// getDocumentSectionIndentLevelForRow:withNumberOfGroups: is implemented in the
// Extras category but not exposed in its public header; redeclare it here so the
// pure-logic indent mapping can be characterized.
@interface RptqDocumentSection (PrivateTestHooks)
+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row
							  withNumberOfGroups:(NSInteger)numberOfGroups;
@end

#pragma mark - Helpers

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	// Testing.h's pass() carries a printf format, so the error object cannot be
	// printed with %@; the check is the same one the Xcode helper made.
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

static RptqDocumentSection *sectionOfType(MADDocumentSectionType type,
										  RptqStoreContext *context) {
	return [RptqDocumentSection newDocumentSectionOfType:type forManagedObjectContext:context];
}

#pragma mark - Key-path constants

static void testSimpleKeyPathConstants(void) {
	MAD_PASS_EQUAL([RptqDocumentSection keyPathNumberOfRows], @"numberOfRows", "the number-of-rows key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathType], @"type", "the type key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathWrappingStyle], @"wrappingStyle", "the wrapping-style key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathVisibility], @"visibility", "the visibility key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathHeight], @"height", "the height key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathLayoutHeight], @"layoutHeight", "the layout-height key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInGroup], @"inGroup", "the in-group key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInReport], @"inReport", "the in-report key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInPageHeader], @"inReportPageHeader", "the in-page-header key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInPageFooter], @"inReportPageFooter", "the in-page-footer key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInReportHeader], @"inReportReportHeader", "the in-report-header key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInReportFooter], @"inReportReportFooter", "the in-report-footer key path");
}

static void testCompositeKeyPathConstants(void) {
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInGroupSort], @"inGroup.sort", "the in-group sort key path");
	MAD_PASS_EQUAL([RptqDocumentSection keyPathInGroupWeight], @"inGroup.weight", "the in-group weight key path");
}

#pragma mark - Section-type mapping

static void testGetSectionTypeForRowWithZeroGroups(void) {
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:0 withNumberOfGroups:0] == MADDocumentSectionTypeReportHeader, "row 0 is the report header");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:1 withNumberOfGroups:0] == MADDocumentSectionTypePageHeader, "row 1 is the page header");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:2 withNumberOfGroups:0] == MADDocumentSectionTypeBody, "row 2 is the body");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:3 withNumberOfGroups:0] == MADDocumentSectionTypePageFooter, "row 3 is the page footer");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:4 withNumberOfGroups:0] == MADDocumentSectionTypeReportFooter, "row 4 is the report footer");
}

static void testGetSectionTypeForRowWithOneGroup(void) {
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:0 withNumberOfGroups:1] == MADDocumentSectionTypeReportHeader, "row 0 is the report header with one group");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:1 withNumberOfGroups:1] == MADDocumentSectionTypePageHeader, "row 1 is the page header with one group");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:2 withNumberOfGroups:1] == MADDocumentSectionTypeGroupHeader, "row 2 is the group header");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:3 withNumberOfGroups:1] == MADDocumentSectionTypeBody, "row 3 is the body with one group");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:4 withNumberOfGroups:1] == MADDocumentSectionTypeGroupFooter, "row 4 is the group footer");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:5 withNumberOfGroups:1] == MADDocumentSectionTypePageFooter, "row 5 is the page footer with one group");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:6 withNumberOfGroups:1] == MADDocumentSectionTypeReportFooter, "row 6 is the report footer with one group");
}

static void testGetSectionTypeForRowWithNumberOfSections(void) {
	// numberOfSections is converted to group count as (sections - 5) / 2.
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:2 withNumberOfSections:5] == MADDocumentSectionTypeBody, "row 2 of 5 sections is the body");
	MAD_PASS([RptqDocumentSection getSectionTypeforRow:2 withNumberOfSections:7] == MADDocumentSectionTypeGroupHeader, "row 2 of 7 sections is a group header");
}

static void testGetDocumentSectionIndentLevelForRow(void) {
	// body index = 2 + numberOfGroups; indent mirrors around the body row.
	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:0 withNumberOfGroups:0] == 0, "row 0 indents at 0 with no groups");
	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:2 withNumberOfGroups:0] == 2, "the body row indents fully with no groups");
	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:4 withNumberOfGroups:0] == 0, "the last row indents at 0 with no groups");

	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:0 withNumberOfGroups:1] == 0, "row 0 indents at 0 with one group");
	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:3 withNumberOfGroups:1] == 3, "the body row indents fully with one group");
	MAD_PASS([RptqDocumentSection getDocumentSectionIndentLevelForRow:6 withNumberOfGroups:1] == 0, "the last row indents at 0 with one group");
}

#pragma mark - Section factory and type

static void testNewDocumentSectionOfType(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *section = sectionOfType(MADDocumentSectionTypeBody, context);

	MAD_PASS(section != nil, "the factory returns a section");
	MAD_PASS(section.type == (int16_t)MADDocumentSectionTypeBody, "the section carries the requested type");
	MAD_PASS(section.visibility, "a new section is visible");
	MAD_PASS([section getDocumentSectionType] == MADDocumentSectionTypeBody, "the derived section type is the body");
}

#pragma mark - Form feed (wrapping style)

static void testProducesFormFeedDefaultsNo(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *section = sectionOfType(MADDocumentSectionTypeBody, context);
	MAD_PASS(![section producesFormFeed], "a new section does not produce a form feed");
}

static void testSetProducesFormFeed(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *section = sectionOfType(MADDocumentSectionTypeBody, context);

	[section setProducesFormFeed:YES];
	MAD_PASS([section producesFormFeed], "enabling the form feed sticks");
	MAD_PASS(section.wrappingStyle == (int16_t)RptqDocumentSectionWrappingStyleNewPageAfter, "enabling sets the new-page-after style");

	[section setProducesFormFeed:NO];
	MAD_PASS(![section producesFormFeed], "disabling the form feed sticks");
	MAD_PASS(section.wrappingStyle == (int16_t)RptqDocumentSectionWrappingStyleStandard, "disabling restores the standard style");
}

#pragma mark - Localized display name

static void testLocalizedDisplayName(void) {
	RptqStoreContext *context = inMemoryContext();
	MAD_PASS_EQUAL([sectionOfType(MADDocumentSectionTypeReportHeader, context) localizedDisplayName], @"Report Header", "the report-header display name");
	MAD_PASS_EQUAL([sectionOfType(MADDocumentSectionTypePageHeader, context) localizedDisplayName], @"Page Header", "the page-header display name");
	MAD_PASS_EQUAL([sectionOfType(MADDocumentSectionTypeBody, context) localizedDisplayName], @"Report Detail", "the body display name");
	MAD_PASS_EQUAL([sectionOfType(MADDocumentSectionTypePageFooter, context) localizedDisplayName], @"Page Footer", "the page-footer display name");
	MAD_PASS_EQUAL([sectionOfType(MADDocumentSectionTypeReportFooter, context) localizedDisplayName], @"Report Footer", "the report-footer display name");
}

#pragma mark - Header/footer section lookup

static void testHeaderAndFooterSectionInSections(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *header = sectionOfType(MADDocumentSectionTypeGroupHeader, context);
	RptqDocumentSection *footer = sectionOfType(MADDocumentSectionTypeGroupFooter, context);
	RptqDocumentSection *body = sectionOfType(MADDocumentSectionTypeBody, context);

	NSSet *sections = [NSSet setWithObjects:body, footer, header, nil];

	MAD_PASS_EQUAL([RptqDocumentSection headerSectionInSections:sections], header, "the header is found in the section set");
	MAD_PASS_EQUAL([RptqDocumentSection footerSectionInSections:sections], footer, "the footer is found in the section set");
}

static void testHeaderSectionInSectionsWithoutHeaderReturnsNil(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *body = sectionOfType(MADDocumentSectionTypeBody, context);
	NSSet *sections = [NSSet setWithObject:body];
	MAD_PASS([RptqDocumentSection headerSectionInSections:sections] == nil, "a set without a header finds no header");
}

MAD_TEST_MAIN("MADRptqDocumentSectionTests",
	MAD_TEST(testSimpleKeyPathConstants),
	MAD_TEST(testCompositeKeyPathConstants),
	MAD_TEST(testGetSectionTypeForRowWithZeroGroups),
	MAD_TEST(testGetSectionTypeForRowWithOneGroup),
	MAD_TEST(testGetSectionTypeForRowWithNumberOfSections),
	MAD_TEST(testGetDocumentSectionIndentLevelForRow),
	MAD_TEST(testNewDocumentSectionOfType),
	MAD_TEST(testProducesFormFeedDefaultsNo),
	MAD_TEST(testSetProducesFormFeed),
	MAD_TEST(testLocalizedDisplayName),
	MAD_TEST(testHeaderAndFooterSectionInSections),
	MAD_TEST(testHeaderSectionInSectionsWithoutHeaderReturnsNil));
