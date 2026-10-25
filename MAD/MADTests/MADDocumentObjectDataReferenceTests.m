//
//  MADDocumentObjectDataReferenceTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReference: the per-element handle
//  the print page renderer hands around.  Pinned here: the factory's element-type ->
//  subclass mapping (including the whitespace fall-through to the base class), the
//  initialiser's page/item/itemID wiring (item and datasource are weak), the formatted-
//  string fall-through to the element, -fontAttributes: delegation, and the copy.
//
//  The copy is the interesting one: -copyWithZone: carries item, page index, row id and
//  datasource across, but not the delegate, so a copied reference answers nil from
//  -fontAttributes unless a delegate is set on it again.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>

#import "MADDocumentObjectDataReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

// -delegate is implemented but declared only in the class extension; this test-only
// category is the deliberate bridge.
@interface MADDocumentObjectDataReference (TestSurface)
- (id <MADDocumentObjectDataReferenceProtocol>)delegate;
@end

// Records what the reference asks of its delegate.
@interface MADDataReferenceDelegateDouble : NSObject <MADDocumentObjectDataReferenceProtocol>
@property (nonatomic, strong) NSDictionary <NSString *, id> *attributes;
@end

@implementation MADDataReferenceDelegateDouble

- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef {
	return self.attributes;
}

@end

@interface MADDocumentObjectDataReferenceTests : XCTestCase
@end

@implementation MADDocumentObjectDataReferenceTests

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

- (MADDocumentObjectDataReference *)referenceOfType:(MADPrintPageElementType)type
											context:(RptqStoreContext *)context
										   delegate:(id <MADDocumentObjectDataReferenceProtocol>)delegate
										 datasource:(id <MADPrintPageRendererDataSourceProtocol>)datasource {
	RptqDocumentElement *element = [context insertObjectForEntity:@"RptqDocumentElement" identifier:0];
	element.type = type;
	return [MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																 delegate:delegate
																	 page:3
																	 item:element
																   itemID:42];
}

#pragma mark - Factory

- (void)testFactorySelectsConcreteClassForElementType {
	RptqStoreContext *context = [self inMemoryContext];

	MADDocumentObjectDataReference *labelStatic = [self referenceOfType:MADPrintPageElementTypeLabelStatic context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *labelDynamic = [self referenceOfType:MADPrintPageElementTypeLabelDynamic context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *aggregate = [self referenceOfType:MADPrintPageElementTypeAggregate context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *image = [self referenceOfType:MADPrintPageElementTypeImage context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *barcode = [self referenceOfType:MADPrintPageElementTypeBarcode context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *whitespace = [self referenceOfType:MADPrintPageElementTypeWhtiespace context:context delegate:nil datasource:nil];
	MADDocumentObjectDataReference *chart = [self referenceOfType:MADPrintPageElementTypeChart context:context delegate:nil datasource:nil];

	XCTAssertEqualObjects(NSStringFromClass([labelStatic class]), @"MADDocumentObjectDataReferenceLabelStatic");
	XCTAssertEqualObjects(NSStringFromClass([labelDynamic class]), @"MADDocumentObjectDataReferenceLabelDynamic");
	XCTAssertEqualObjects(NSStringFromClass([aggregate class]), @"MADDocumentObjectDataReferenceAggregate");
	XCTAssertEqualObjects(NSStringFromClass([image class]), @"MADDocumentObjectDataReferenceImage");
	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADDocumentObjectDataReferenceBarcode");
	// Whitespace (and anything the switch does not name) falls through to the base class.
	XCTAssertEqualObjects(NSStringFromClass([whitespace class]), @"MADDocumentObjectDataReference");
	XCTAssertEqualObjects(NSStringFromClass([chart class]), @"MADDocumentObjectDataReference");
}

#pragma mark - Wiring

- (void)testReferenceStoresPageItemAndIDs {
	RptqStoreContext *context = [self inMemoryContext];
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:delegate
														   datasource:nil];

	XCTAssertEqual(reference.pageIndex, (NSUInteger)3);
	XCTAssertEqual(reference.detailRowId, (NSUInteger)42);
	XCTAssertNotNil(reference.item);
	// -type reads the element's own type.
	XCTAssertEqual(reference.type, MADPrintPageElementTypeLabelStatic);
	// The delegate is held, but weakly (the header does not expose the accessor).
	XCTAssertEqual([reference delegate], delegate);
}

- (void)testItemAndDatasourceAreHeldWeakly {
	RptqStoreContext *context = [self inMemoryContext];
	MADDocumentObjectDataReference *reference = nil;

	@autoreleasepool {
		RptqDocumentElement *element = [context insertObjectForEntity:@"RptqDocumentElement" identifier:0];
		element.type = MADPrintPageElementTypeLabelStatic;
		reference = [MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																		  delegate:nil
																			  page:0
																			  item:element
																			itemID:0];
		XCTAssertNotNil(reference.item);
		// The context retains the element, so only its own reference can drop here.
	}

	XCTAssertNotNil(reference.item);
}

#pragma mark - Formatting

- (void)testFormattedStringFallsThroughToTheElement {
	RptqStoreContext *context = [self inMemoryContext];
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:nil
														   datasource:nil];

	NSString *formatted = [reference formattedString:MADDataTypeString forValue:@"abc"];
	XCTAssertEqualObjects(formatted, @"abc");

	// A NULL from the data reads as empty text.
	NSString *formattedNull = [reference formattedString:MADDataTypeString forValue:[NSNull null]];
	XCTAssertEqualObjects(formattedNull, @"");
}

#pragma mark - Delegate

- (void)testFontAttributesComeFromTheDelegate {
	RptqStoreContext *context = [self inMemoryContext];
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	delegate.attributes = @{ @"FamilyName": @"Helvetica Neue" };
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:delegate
														   datasource:nil];

	NSDictionary *attributes = [reference fontAttributes];
	XCTAssertEqualObjects(attributes, delegate.attributes);
}

- (void)testFontAttributesAreNilWithoutADelegate {
	RptqStoreContext *context = [self inMemoryContext];
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:nil
														   datasource:nil];

	NSDictionary *attributes = [reference fontAttributes];
	XCTAssertNil(attributes);
}

#pragma mark - Copy

- (void)testCopyCarriesItemAndIndexesButNotTheDelegate {
	RptqStoreContext *context = [self inMemoryContext];
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	delegate.attributes = @{ @"FamilyName": @"Helvetica Neue" };
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:delegate
														   datasource:nil];

	MADDocumentObjectDataReference *copy = [reference copy];

	XCTAssertEqualObjects(NSStringFromClass([copy class]), NSStringFromClass([reference class]));
	XCTAssertEqual(copy.item, reference.item);
	XCTAssertEqual(copy.pageIndex, reference.pageIndex);
	XCTAssertEqual(copy.detailRowId, reference.detailRowId);
	XCTAssertEqual(copy.datasource, reference.datasource);
	// The delegate is not part of the copy, so the copy cannot format text.
	XCTAssertNil([copy delegate]);
	NSDictionary *copyAttributes = [copy fontAttributes];
	XCTAssertNil(copyAttributes);
}

#pragma mark - Font descriptors

- (void)testFontDescriptorsStartNil {
	RptqStoreContext *context = [self inMemoryContext];
	MADDocumentObjectDataReference *reference = [self referenceOfType:MADPrintPageElementTypeLabelStatic
															  context:context
															 delegate:nil
														   datasource:nil];

	// The property is declared but nothing ever fills it; -dealloc only clears it.
	XCTAssertNil(reference.fontDescriptors);
}

@end
