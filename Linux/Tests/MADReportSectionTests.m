//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportSectionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADReportSectionTests.m: MADReportSection is the
//  wrapper a RptqDocumentSection is presented through.  -initWithReportSection:
//  actually returns one of seven private subclasses chosen by the row's type;
//  everything else -- type, height, visibility, identifier, and the document
//  section itself -- is answered by the wrapped row.
//
//  The layout-manager case does not port: -layoutManager builds a
//  MADSectionLayoutManager, which is Apple-only (MADSectionLayoutManager.m is
//  excluded from the Linux build and the property is #if __APPLE__ in
//  MADReportSection.h).  That one case stays on the Xcode side.
//
//  Two things stand as they are: -objectID is never assigned by the initialiser
//  (it stays nil), and the display names for group sections come from the
//  group's field name, which is "(null)" when the section has no group.
//

#import "MADTestSupport.h"

#import <MAD/MADReportSection.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/MADocumentSectionType.h>

#pragma mark - Fixture

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

static RptqDocumentSection *sectionOfType(MADDocumentSectionType type, RptqStoreContext *context) {
	return [RptqDocumentSection newDocumentSectionOfType:type forManagedObjectContext:context];
}

static MADReportSection *reportSectionOfType(MADDocumentSectionType type, RptqStoreContext *context) {
	RptqDocumentSection *row = sectionOfType(type, context);
	return [[MADReportSection alloc] initWithReportSection:row];
}

#pragma mark - Factory

static void testFactoryReturnsAPrivateSubclassPerSectionType(void) {
	RptqStoreContext *context = inMemoryContext();

	MADReportSection *reportHeader = reportSectionOfType(MADDocumentSectionTypeReportHeader, context);
	MADReportSection *pageHeader = reportSectionOfType(MADDocumentSectionTypePageHeader, context);
	MADReportSection *groupHeader = reportSectionOfType(MADDocumentSectionTypeGroupHeader, context);
	MADReportSection *detail = reportSectionOfType(MADDocumentSectionTypeBody, context);
	MADReportSection *groupFooter = reportSectionOfType(MADDocumentSectionTypeGroupFooter, context);
	MADReportSection *pageFooter = reportSectionOfType(MADDocumentSectionTypePageFooter, context);
	MADReportSection *reportFooter = reportSectionOfType(MADDocumentSectionTypeReportFooter, context);

	MAD_PASS_EQUAL(NSStringFromClass([reportHeader class]), @"MADReportSectionReportHeader", "the report header wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([pageHeader class]), @"MADReportSectionPageHeader", "the page header wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([groupHeader class]), @"MADReportSectionGroupHeader", "the group header wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([detail class]), @"MADReportSectionDetail", "the detail wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([groupFooter class]), @"MADReportSectionGroupFooter", "the group footer wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([pageFooter class]), @"MADReportSectionPageFooter", "the page footer wrapper");
	MAD_PASS_EQUAL(NSStringFromClass([reportFooter class]), @"MADReportSectionReportFooter", "the report footer wrapper");
}

#pragma mark - Delegation to the row

static void testTypeHeightVisibilityAndIdentifierComeFromTheRow(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *row = sectionOfType(MADDocumentSectionTypeBody, context);
	row.height = 42.0;
	row.visibility = NO;
	MADReportSection *section = [[MADReportSection alloc] initWithReportSection:row];

	MAD_PASS(section.documentSection == row, "the wrapper answers the row it wraps");
	MAD_PASS(section.type == MADDocumentSectionTypeBody, "the type comes from the row");
	MAD_PASS(section.height == 42.0, "the height comes from the row");
	MAD_PASS(!section.isVisible, "the visibility comes from the row");
	MAD_PASS(section.identifier == (NSInteger)row.identifier, "the identifier comes from the row");
}

static void testObjectIDIsNeverSetByTheInitialiser(void) {
	RptqStoreContext *context = inMemoryContext();
	MADReportSection *section = reportSectionOfType(MADDocumentSectionTypeReportHeader, context);

	MAD_PASS(section.objectID == nil, "the object id is never set by the initialiser");
}

#pragma mark - Display names

static void testFixedSectionDisplayNames(void) {
	RptqStoreContext *context = inMemoryContext();

	MADReportSection *reportHeader = reportSectionOfType(MADDocumentSectionTypeReportHeader, context);
	MADReportSection *pageHeader = reportSectionOfType(MADDocumentSectionTypePageHeader, context);
	MADReportSection *detail = reportSectionOfType(MADDocumentSectionTypeBody, context);
	MADReportSection *pageFooter = reportSectionOfType(MADDocumentSectionTypePageFooter, context);
	MADReportSection *reportFooter = reportSectionOfType(MADDocumentSectionTypeReportFooter, context);

	MAD_PASS_EQUAL(reportHeader.localizedDisplayName, @"Report Header", "the report header name");
	MAD_PASS_EQUAL(pageHeader.localizedDisplayName, @"Page Header", "the page header name");
	MAD_PASS_EQUAL(detail.localizedDisplayName, @"Report Detail", "the detail name");
	MAD_PASS_EQUAL(pageFooter.localizedDisplayName, @"Page Footer", "the page footer name");
	MAD_PASS_EQUAL(reportFooter.localizedDisplayName, @"Report Footer", "the report footer name");
}

static void testGroupSectionDisplayNamesUseTheGroupFieldName(void) {
	RptqStoreContext *context = inMemoryContext();

	// No group is attached, so the name inside the parentheses is the string that
	// -initWithFormat: gives a nil argument.
	MADReportSection *groupHeader = reportSectionOfType(MADDocumentSectionTypeGroupHeader, context);
	MADReportSection *groupFooter = reportSectionOfType(MADDocumentSectionTypeGroupFooter, context);

	MAD_PASS_EQUAL(groupHeader.localizedDisplayName, @"Group Header ((null))", "the group header name uses the group field name");
	MAD_PASS_EQUAL(groupFooter.localizedDisplayName, @"Group Footer - ((null))", "the group footer name uses the group field name");
}

static void testInitWithAnUnknownTypeReturnsNil(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentSection *row = (RptqDocumentSection *)[context insertObjectForEntity:@"RptqDocumentSection" identifier:0];
	row.type = MADDocumentSectionTypeUnknown;

	MADReportSection *section = [[MADReportSection alloc] initWithReportSection:row];

	// The initialiser's switch has no case for Unknown; the strong local is
	// zero-initialised, so the answer is nil rather than a wrapper.  See BUGS.md for
	// the recursion -identifier hits on a wrapper whose row is unwired.
	MAD_PASS(section == nil, "an unknown section type returns nil");
}

MAD_TEST_MAIN("MADReportSectionTests",
	MAD_TEST(testFactoryReturnsAPrivateSubclassPerSectionType),
	MAD_TEST(testTypeHeightVisibilityAndIdentifierComeFromTheRow),
	MAD_TEST(testObjectIDIsNeverSetByTheInitialiser),
	MAD_TEST(testFixedSectionDisplayNames),
	MAD_TEST(testGroupSectionDisplayNamesUseTheGroupFieldName),
	MAD_TEST(testInitWithAnUnknownTypeReturnsNil));
