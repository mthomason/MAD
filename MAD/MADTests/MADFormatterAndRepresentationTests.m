//
//  MADFormatterAndRepresentationTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 2 coverage for the MAD framework: formatters and report value types.
//  These types are stateful but carry no Core Data or database dependencies:
//    * MADDataFormatter / MADTableFormatter (query binding + needsFormat/didRefresh).
//    * MADCurrencyFormatter (enabled/decimalCount/locale, copy, secure coding).
//    * MADDocumentObjectTypeDescriptor (type titles + localized strings).
//    * MADReportLineRepresentation / MADReportTextRepresentation.
//    * MADReportRow / MADReportRows (readonly collections on fresh instances).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADQuery.h>

#import "MADDataFormatter.h"
#import "MADTableFormatter.h"
#import "MADCurrencyFormatter.h"
#import "MADDocumentObjectTypeDescriptor.h"
#import "MADReportLineRepresentation.h"
#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import "MADReportRow.h"
#import "MADReportRows.h"

// A MADQuery that formally satisfies the two protocols MADDataFormatter requires
// (MADQueryDatabaseProtocol / MADQueryDatabaseRangeProtocol), so the formatter
// tests can pass a real, conforming query rather than nil.
@interface MADFormatterQueryDouble : MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol>
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, assign) NSUInteger offset;
@end

@implementation MADFormatterQueryDouble
@end

// A MADReportPageRepresentation with fixed, caller-supplied counts so the
// MADReportTextRepresentation aggregation tests don't depend on the full
// page/section/row/element tree.
@interface MADFixedPageDouble : MADReportPageRepresentation
@property (nonatomic, assign) NSUInteger fixedCharacters;
@property (nonatomic, assign) NSUInteger fixedElements;
@end

@implementation MADFixedPageDouble
- (NSUInteger)characterCount { return self.fixedCharacters; }
- (NSUInteger)elementCount { return self.fixedElements; }
@end

@interface MADFormatterAndRepresentationTests : XCTestCase
@end

@implementation MADFormatterAndRepresentationTests

#pragma mark - MADDataFormatter / MADTableFormatter

- (void)testDataFormatterInitWithNilQuery {
	MADDataFormatter *formatter = [[MADDataFormatter alloc] initWithQuery:nil];
	XCTAssertNil(formatter.query);
	XCTAssertFalse(formatter.didRefresh);
	XCTAssertTrue(formatter.needsFormat);
}

- (void)testDataFormatterInitStoresQuery {
	MADFormatterQueryDouble *query = [[MADFormatterQueryDouble alloc] init];
	MADDataFormatter *formatter = [[MADDataFormatter alloc] initWithQuery:query];
	XCTAssertEqual(formatter.query, query);
	XCTAssertFalse(formatter.didRefresh);
	XCTAssertTrue(formatter.needsFormat);
}

- (void)testDataFormatterNewDataFormatter {
	MADFormatterQueryDouble *query = [[MADFormatterQueryDouble alloc] init];
	MADDataFormatter *formatter = [MADDataFormatter newDataFormatter:query];
	XCTAssertEqual(formatter.query, query);
	XCTAssertFalse(formatter.didRefresh);
}

- (void)testDataFormatterDidRefreshSettable {
	MADDataFormatter *formatter = [[MADDataFormatter alloc] initWithQuery:nil];
	formatter.didRefresh = YES;
	XCTAssertTrue(formatter.didRefresh);
	formatter.didRefresh = NO;
	XCTAssertFalse(formatter.didRefresh);
}

- (void)testTableFormatterInitWithQuery {
	MADFormatterQueryDouble *query = [[MADFormatterQueryDouble alloc] init];
	MADTableFormatter *formatter = [[MADTableFormatter alloc] initWithQuery:query];
	XCTAssertEqual(formatter.query, query);
	XCTAssertFalse(formatter.didRefresh);
	XCTAssertTrue(formatter.needsFormat);
}

#pragma mark - MADCurrencyFormatter

- (void)testCurrencyFormatterDefaults {
	MADCurrencyFormatter *formatter = [[MADCurrencyFormatter alloc] init];
	XCTAssertFalse(formatter.enabled);
	XCTAssertEqual(formatter.decimalCount, (NSInteger)0);
	XCTAssertNil(formatter.locale);
	XCTAssertTrue([MADCurrencyFormatter supportsSecureCoding]);
}

- (void)testCurrencyFormatterSetters {
	MADCurrencyFormatter *formatter = [[MADCurrencyFormatter alloc] init];
	formatter.enabled = YES;
	formatter.decimalCount = 4;
	formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
	XCTAssertTrue(formatter.enabled);
	XCTAssertEqual(formatter.decimalCount, (NSInteger)4);
	XCTAssertEqualObjects(formatter.locale.localeIdentifier, @"en_GB");
}

- (void)testCurrencyFormatterCopy {
	MADCurrencyFormatter *formatter = [[MADCurrencyFormatter alloc] init];
	formatter.enabled = YES;
	formatter.decimalCount = 2;
	formatter.locale = [NSLocale localeWithLocaleIdentifier:@"fr_FR"];

	MADCurrencyFormatter *copy = [formatter copy];
	XCTAssertNotNil(copy);
	XCTAssertTrue(copy.enabled);
	XCTAssertEqual(copy.decimalCount, (NSInteger)2);
	XCTAssertEqualObjects(copy.locale.localeIdentifier, @"fr_FR");
}

- (void)testCurrencyFormatterSecureCodingRoundTrip {
	MADCurrencyFormatter *formatter = [[MADCurrencyFormatter alloc] init];
	formatter.enabled = YES;
	formatter.decimalCount = 3;
	formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:formatter requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADCurrencyFormatter *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADCurrencyFormatter class]
																	  fromData:data
																		 error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertTrue(decoded.enabled);
	XCTAssertEqual(decoded.decimalCount, (NSInteger)3);
	XCTAssertEqualObjects(decoded.locale.localeIdentifier, @"en_US");
}

#pragma mark - MADDocumentObjectTypeDescriptor

- (void)testDocumentObjectTypeTitleConstants {
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleDynamic, @"Data Label");
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleStatic, @"Static Label");
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleWhitespace, @"Whitespace");
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleAggregate, @"Aggregate");
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleImage, @"Image");
	XCTAssertEqualObjects(MADDocumentObjectTypeTitleBarcode, @"Barcode");
}

- (void)testDocumentObjectTypeAddDetailConstants {
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailDynamic, @"Add a dynamic data field label.");
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailStatic, @"Add a static text document object.");
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailWhitespace, @"Add an empty element.");
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailAggregate, @"Add a grouping of data.");
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailImage, @"Add a static image.");
	XCTAssertEqualObjects(MADDocumentObjectTypeAddDetailBarcode, @"Add a barcode element.");
}

- (void)testLocalizedStringForKnownTypes {
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeLabelDynamic], @"Data Label");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeLabelStatic], @"Static Label");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeAggregate], @"Aggregate");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeImage], @"Image");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeWhtiespace], @"Whitespace");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeBarcode], @"Barcode");
}

- (void)testLocalizedStringForUnknownTypes {
	// Types absent from the descriptor map fall back to an empty string.
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeChart], @"");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeFormula], @"");
	XCTAssertEqualObjects([MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeGroupKey], @"");
}

#pragma mark - MADReportLineRepresentation

- (void)testReportLineRepresentationStringObject {
	MADReportLineRepresentation *line = [[MADReportLineRepresentation alloc] initWithObject:@"hello"
																					   type:MADPrintPageElementTypeLabelStatic
																					  frame:CGRectMake(1, 2, 3, 4)];
	XCTAssertEqualObjects(line.label, @"hello");
	XCTAssertEqual(line.characterCount, (NSUInteger)5);
	XCTAssertEqual(line.elementCount, (NSUInteger)1);
	XCTAssertTrue(CGRectEqualToRect(line.frame, CGRectMake(1, 2, 3, 4)));
}

- (void)testReportLineRepresentationNonStringObject {
	// A non-string object is replaced by the localized title for the type.
	MADReportLineRepresentation *line = [[MADReportLineRepresentation alloc] initWithObject:@123
																					   type:MADPrintPageElementTypeAggregate
																					  frame:CGRectZero];
	XCTAssertEqualObjects(line.label, @"Aggregate");
	XCTAssertEqual(line.characterCount, (NSUInteger)9);
	XCTAssertEqual(line.elementCount, (NSUInteger)1);
}

- (void)testReportLineRepresentationInitDefaults {
	MADReportLineRepresentation *line = [[MADReportLineRepresentation alloc] init];
	XCTAssertEqualObjects(line.label, @"");
	XCTAssertEqual(line.characterCount, (NSUInteger)0);
	XCTAssertEqual(line.elementCount, (NSUInteger)1);
	XCTAssertTrue(CGRectEqualToRect(line.frame, CGRectZero));
}

#pragma mark - MADReportTextRepresentation

- (void)testTextRepresentationInitEmpty {
	MADReportTextRepresentation *representation = [[MADReportTextRepresentation alloc] init];
	XCTAssertEqual(representation.numberOfPages, (NSUInteger)0);
	XCTAssertNil([representation pageIndex:0]);
}

- (void)testTextRepresentationPageMapCRUD {
	MADReportTextRepresentation *representation = [[MADReportTextRepresentation alloc] initWithPageCount:2];
	MADFixedPageDouble *page = [[MADFixedPageDouble alloc] initWithNumberOfSections:0];

	[representation setPage:page forPageIndex:3];
	XCTAssertEqual(representation.numberOfPages, (NSUInteger)1);
	XCTAssertEqualObjects([representation pageIndex:3], page);
	XCTAssertNil([representation pageIndex:0]);
}

- (void)testTextRepresentationRemoveAllPages {
	MADReportTextRepresentation *representation = [[MADReportTextRepresentation alloc] init];
	[representation setPage:[[MADFixedPageDouble alloc] initWithNumberOfSections:0] forPageIndex:0];
	[representation setPage:[[MADFixedPageDouble alloc] initWithNumberOfSections:0] forPageIndex:1];
	XCTAssertEqual(representation.numberOfPages, (NSUInteger)2);

	[representation removeAllPages];
	XCTAssertEqual(representation.numberOfPages, (NSUInteger)0);
	XCTAssertNil([representation pageIndex:0]);
}

- (void)testTextRepresentationEmptyCountsAreZero {
	MADReportTextRepresentation *representation = [[MADReportTextRepresentation alloc] init];
	XCTAssertEqual([representation characterCount], (NSUInteger)0);
	XCTAssertEqual([representation elementCount], (NSUInteger)0);
}

- (void)testTextRepresentationCountsSumPageValues {
	// The counts sum the page *values*; enumerating the page map directly yielded the
	// NSNumber keys and raised an unrecognized-selector exception.
	MADReportTextRepresentation *representation = [[MADReportTextRepresentation alloc] init];
	MADFixedPageDouble *page = [[MADFixedPageDouble alloc] initWithNumberOfSections:0];
	[representation setPage:page forPageIndex:0];
	XCTAssertEqual([representation characterCount], [page characterCount]);
	XCTAssertEqual([representation elementCount], [page elementCount]);
}

#pragma mark - MADReportRow / MADReportRows

- (void)testReportRowEmpty {
	MADReportRow *row = [[MADReportRow alloc] init];
	XCTAssertNil(row.hasDocumentObjects);
}

- (void)testReportRowsEmpty {
	MADReportRows *rows = [[MADReportRows alloc] init];
	XCTAssertNil(rows.rows);
}

@end
