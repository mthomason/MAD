//
//  MADReportSectionTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADReportSection: the wrapper a RptqDocumentSection is
//  presented through.  -initWithReportSection: actually returns one of seven private
//  subclasses chosen by the row's type; everything else -- type, height, visibility,
//  identifier, and the document section itself -- is answered by the wrapped row, and the
//  layout manager is built lazily from that row and then memoized.
//
//  Two things stand as they are: -objectID is never assigned by the initialiser (it stays
//  nil), and the display names for group sections come from the group's field name, which
//  is "(null)" when the section has no group.
//

#import <XCTest/XCTest.h>

#import "MADReportSection.h"
#import "MADSectionLayoutManager.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "MADocumentSectionType.h"

@interface MADReportSectionTests : XCTestCase
@end

@implementation MADReportSectionTests

#pragma mark - Fixture

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

- (RptqDocumentSection *)sectionOfType:(MADDocumentSectionType)type inContext:(RptqStoreContext *)context {
	return [RptqDocumentSection newDocumentSectionOfType:type forManagedObjectContext:context];
}

- (MADReportSection *)reportSectionOfType:(MADDocumentSectionType)type inContext:(RptqStoreContext *)context {
	RptqDocumentSection *row = [self sectionOfType:type inContext:context];
	return [[MADReportSection alloc] initWithReportSection:row];
}

#pragma mark - Factory

- (void)testFactoryReturnsAPrivateSubclassPerSectionType {
	RptqStoreContext *context = [self inMemoryContext];

	MADReportSection *reportHeader = [self reportSectionOfType:MADDocumentSectionTypeReportHeader inContext:context];
	MADReportSection *pageHeader = [self reportSectionOfType:MADDocumentSectionTypePageHeader inContext:context];
	MADReportSection *groupHeader = [self reportSectionOfType:MADDocumentSectionTypeGroupHeader inContext:context];
	MADReportSection *detail = [self reportSectionOfType:MADDocumentSectionTypeBody inContext:context];
	MADReportSection *groupFooter = [self reportSectionOfType:MADDocumentSectionTypeGroupFooter inContext:context];
	MADReportSection *pageFooter = [self reportSectionOfType:MADDocumentSectionTypePageFooter inContext:context];
	MADReportSection *reportFooter = [self reportSectionOfType:MADDocumentSectionTypeReportFooter inContext:context];

	XCTAssertEqualObjects(NSStringFromClass([reportHeader class]), @"MADReportSectionReportHeader");
	XCTAssertEqualObjects(NSStringFromClass([pageHeader class]), @"MADReportSectionPageHeader");
	XCTAssertEqualObjects(NSStringFromClass([groupHeader class]), @"MADReportSectionGroupHeader");
	XCTAssertEqualObjects(NSStringFromClass([detail class]), @"MADReportSectionDetail");
	XCTAssertEqualObjects(NSStringFromClass([groupFooter class]), @"MADReportSectionGroupFooter");
	XCTAssertEqualObjects(NSStringFromClass([pageFooter class]), @"MADReportSectionPageFooter");
	XCTAssertEqualObjects(NSStringFromClass([reportFooter class]), @"MADReportSectionReportFooter");
}

#pragma mark - Delegation to the row

- (void)testTypeHeightVisibilityAndIdentifierComeFromTheRow {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *row = [self sectionOfType:MADDocumentSectionTypeBody inContext:context];
	row.height = 42.0;
	row.visibility = NO;
	MADReportSection *section = [[MADReportSection alloc] initWithReportSection:row];

	XCTAssertEqual(section.documentSection, row);
	XCTAssertEqual(section.type, MADDocumentSectionTypeBody);
	XCTAssertEqual(section.height, 42.0);
	XCTAssertFalse(section.isVisible);
	XCTAssertEqual(section.identifier, (NSInteger)row.identifier);
}

- (void)testObjectIDIsNeverSetByTheInitialiser {
	RptqStoreContext *context = [self inMemoryContext];
	MADReportSection *section = [self reportSectionOfType:MADDocumentSectionTypeReportHeader inContext:context];

	XCTAssertNil(section.objectID);
}

#pragma mark - Display names

- (void)testFixedSectionDisplayNames {
	RptqStoreContext *context = [self inMemoryContext];

	MADReportSection *reportHeader = [self reportSectionOfType:MADDocumentSectionTypeReportHeader inContext:context];
	MADReportSection *pageHeader = [self reportSectionOfType:MADDocumentSectionTypePageHeader inContext:context];
	MADReportSection *detail = [self reportSectionOfType:MADDocumentSectionTypeBody inContext:context];
	MADReportSection *pageFooter = [self reportSectionOfType:MADDocumentSectionTypePageFooter inContext:context];
	MADReportSection *reportFooter = [self reportSectionOfType:MADDocumentSectionTypeReportFooter inContext:context];

	XCTAssertEqualObjects(reportHeader.localizedDisplayName, @"Report Header");
	XCTAssertEqualObjects(pageHeader.localizedDisplayName, @"Page Header");
	XCTAssertEqualObjects(detail.localizedDisplayName, @"Report Detail");
	XCTAssertEqualObjects(pageFooter.localizedDisplayName, @"Page Footer");
	XCTAssertEqualObjects(reportFooter.localizedDisplayName, @"Report Footer");
}

- (void)testGroupSectionDisplayNamesUseTheGroupFieldName {
	RptqStoreContext *context = [self inMemoryContext];

	// No group is attached, so the name inside the parentheses is the string that
	// -initWithFormat: gives a nil argument.
	MADReportSection *groupHeader = [self reportSectionOfType:MADDocumentSectionTypeGroupHeader inContext:context];
	MADReportSection *groupFooter = [self reportSectionOfType:MADDocumentSectionTypeGroupFooter inContext:context];

	XCTAssertEqualObjects(groupHeader.localizedDisplayName, @"Group Header ((null))");
	XCTAssertEqualObjects(groupFooter.localizedDisplayName, @"Group Footer - ((null))");
}

#pragma mark - Layout manager

- (void)testLayoutManagerIsBuiltLazilyAndMemoized {
	RptqStoreContext *context = [self inMemoryContext];
	MADReportSection *section = [self reportSectionOfType:MADDocumentSectionTypeBody inContext:context];

	MADSectionLayoutManager *first = section.layoutManager;
	MADSectionLayoutManager *second = section.layoutManager;

	XCTAssertNotNil(first);
	XCTAssertEqual(first, second);
}

- (void)testInitWithAnUnknownTypeReturnsNil {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentSection *row = [context insertObjectForEntity:@"RptqDocumentSection" identifier:0];
	row.type = MADDocumentSectionTypeUnknown;

	MADReportSection *section = [[MADReportSection alloc] initWithReportSection:row];

	// The initialiser's switch has no case for Unknown; the strong local is
	// zero-initialised, so the answer is nil rather than a wrapper.  See BUGS.md for
	// the recursion -identifier hits on a wrapper whose row is unwired.
	XCTAssertNil(section);
}

@end
