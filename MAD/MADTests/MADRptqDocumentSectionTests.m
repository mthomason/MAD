//
//  MADRptqDocumentSectionTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 4 (Core Data domain model) coverage for RptqDocumentSection.  These tests
//  exercise the pure-logic "Extras" category: section-type mapping by row/group,
//  key-path constants, form-feed wrapping style, and the localized display name.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

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

@interface MADRptqDocumentSectionTests : XCTestCase
@end

@implementation MADRptqDocumentSectionTests

#pragma mark - Helpers

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDocumentSection *)sectionOfType:(MADDocumentSectionType)type
							 inContext:(RptqStoreContext *)context {
	return [RptqDocumentSection newDocumentSectionOfType:type forManagedObjectContext:context];
}

#pragma mark - Key-path constants

- (void)testSimpleKeyPathConstants {
	XCTAssertEqualObjects([RptqDocumentSection keyPathNumberOfRows], @"numberOfRows");
	XCTAssertEqualObjects([RptqDocumentSection keyPathType], @"type");
	XCTAssertEqualObjects([RptqDocumentSection keyPathWrappingStyle], @"wrappingStyle");
	XCTAssertEqualObjects([RptqDocumentSection keyPathVisibility], @"visibility");
	XCTAssertEqualObjects([RptqDocumentSection keyPathHeight], @"height");
	XCTAssertEqualObjects([RptqDocumentSection keyPathLayoutHeight], @"layoutHeight");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInGroup], @"inGroup");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInReport], @"inReport");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInPageHeader], @"inReportPageHeader");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInPageFooter], @"inReportPageFooter");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInReportHeader], @"inReportReportHeader");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInReportFooter], @"inReportReportFooter");
}

- (void)testCompositeKeyPathConstants {
	XCTAssertEqualObjects([RptqDocumentSection keyPathInGroupSort], @"inGroup.sort");
	XCTAssertEqualObjects([RptqDocumentSection keyPathInGroupWeight], @"inGroup.weight");
}

#pragma mark - Section-type mapping

- (void)testGetSectionTypeForRowWithZeroGroups {
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:0 withNumberOfGroups:0], MADDocumentSectionTypeReportHeader);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:1 withNumberOfGroups:0], MADDocumentSectionTypePageHeader);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:2 withNumberOfGroups:0], MADDocumentSectionTypeBody);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:3 withNumberOfGroups:0], MADDocumentSectionTypePageFooter);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:4 withNumberOfGroups:0], MADDocumentSectionTypeReportFooter);
}

- (void)testGetSectionTypeForRowWithOneGroup {
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:0 withNumberOfGroups:1], MADDocumentSectionTypeReportHeader);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:1 withNumberOfGroups:1], MADDocumentSectionTypePageHeader);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:2 withNumberOfGroups:1], MADDocumentSectionTypeGroupHeader);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:3 withNumberOfGroups:1], MADDocumentSectionTypeBody);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:4 withNumberOfGroups:1], MADDocumentSectionTypeGroupFooter);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:5 withNumberOfGroups:1], MADDocumentSectionTypePageFooter);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:6 withNumberOfGroups:1], MADDocumentSectionTypeReportFooter);
}

- (void)testGetSectionTypeForRowWithNumberOfSections {
	// numberOfSections is converted to group count as (sections - 5) / 2.
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:2 withNumberOfSections:5], MADDocumentSectionTypeBody);
	XCTAssertEqual([RptqDocumentSection getSectionTypeforRow:2 withNumberOfSections:7], MADDocumentSectionTypeGroupHeader);
}

- (void)testGetDocumentSectionIndentLevelForRow {
	// body index = 2 + numberOfGroups; indent mirrors around the body row.
	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:0 withNumberOfGroups:0], 0);
	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:2 withNumberOfGroups:0], 2);
	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:4 withNumberOfGroups:0], 0);

	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:0 withNumberOfGroups:1], 0);
	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:3 withNumberOfGroups:1], 3);
	XCTAssertEqual([RptqDocumentSection getDocumentSectionIndentLevelForRow:6 withNumberOfGroups:1], 0);
}

#pragma mark - Section factory and type

- (void)testNewDocumentSectionOfType {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *section = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];

	XCTAssertNotNil(section);
	XCTAssertEqual(section.type, (int16_t)MADDocumentSectionTypeBody);
	XCTAssertTrue(section.visibility);
	XCTAssertEqual([section getDocumentSectionType], MADDocumentSectionTypeBody);
}

#pragma mark - Form feed (wrapping style)

- (void)testProducesFormFeedDefaultsNo {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *section = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];
	XCTAssertFalse([section producesFormFeed]);
}

- (void)testSetProducesFormFeed {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *section = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];

	[section setProducesFormFeed:YES];
	XCTAssertTrue([section producesFormFeed]);
	XCTAssertEqual(section.wrappingStyle, (int16_t)RptqDocumentSectionWrappingStyleNewPageAfter);

	[section setProducesFormFeed:NO];
	XCTAssertFalse([section producesFormFeed]);
	XCTAssertEqual(section.wrappingStyle, (int16_t)RptqDocumentSectionWrappingStyleStandard);
}

#pragma mark - Localized display name

- (void)testLocalizedDisplayName {
	RptqStoreContext *context = [self inMemoryContext];
	XCTAssertEqualObjects([[self sectionOfType:MADDocumentSectionTypeReportHeader inContext:context] localizedDisplayName], @"Report Header");
	XCTAssertEqualObjects([[self sectionOfType:MADDocumentSectionTypePageHeader inContext:context] localizedDisplayName], @"Page Header");
	XCTAssertEqualObjects([[self sectionOfType:MADDocumentSectionTypeBody inContext:context] localizedDisplayName], @"Report Detail");
	XCTAssertEqualObjects([[self sectionOfType:MADDocumentSectionTypePageFooter inContext:context] localizedDisplayName], @"Page Footer");
	XCTAssertEqualObjects([[self sectionOfType:MADDocumentSectionTypeReportFooter inContext:context] localizedDisplayName], @"Report Footer");
}

#pragma mark - Header/footer section lookup

- (void)testHeaderAndFooterSectionInSections {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *header = [self sectionOfType:MADDocumentSectionTypeGroupHeader inContext:context];
	RptqDocumentSection *footer = [self sectionOfType:MADDocumentSectionTypeGroupFooter inContext:context];
	RptqDocumentSection *body = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];

	NSSet *sections = [NSSet setWithObjects:body, footer, header, nil];

	XCTAssertEqualObjects([RptqDocumentSection headerSectionInSections:sections], header);
	XCTAssertEqualObjects([RptqDocumentSection footerSectionInSections:sections], footer);
}

- (void)testHeaderSectionInSectionsWithoutHeaderReturnsNil {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *body = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];
	NSSet *sections = [NSSet setWithObject:body];
	XCTAssertNil([RptqDocumentSection headerSectionInSections:sections]);
}

@end
