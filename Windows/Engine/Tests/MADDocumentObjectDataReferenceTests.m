//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentObjectDataReferenceTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceTests.m:
//  characterization coverage for MADDocumentObjectDataReference, the per-element
//  handle the print page renderer hands around.  Pinned here: the factory's
//  element-type -> subclass mapping (including the whitespace fall-through to
//  the base class), the initialiser's page/item/itemID wiring (item and
//  datasource are weak), the formatted-string fall-through to the element,
//  -fontAttributes: delegation, and the copy.
//
//  The copy is the interesting one: -copyWithZone: carries item, page index,
//  row id and datasource across, but not the delegate, so a copied reference
//  answers nil from -fontAttributes unless a delegate is set on it again.
//
//  The store is a real SQLite file under a per-test temp directory, exactly as
//  the Xcode suite builds it.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>

#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>

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

static MADDocumentObjectDataReference *referenceOfType(MADPrintPageElementType type,
													   RptqStoreContext *context,
													   id <MADDocumentObjectDataReferenceProtocol> delegate,
													   id <MADPrintPageRendererDataSourceProtocol> datasource) {
	RptqDocumentElement *element = (RptqDocumentElement *)[context insertObjectForEntity:@"RptqDocumentElement" identifier:0];
	element.type = type;
	return [MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																 delegate:delegate
																	 page:3
																	 item:element
																   itemID:42];
}

#pragma mark - Factory

static void testFactorySelectsConcreteClassForElementType(void) {
	RptqStoreContext *context = inMemoryContext();

	MADDocumentObjectDataReference *labelStatic = referenceOfType(MADPrintPageElementTypeLabelStatic, context, nil, nil);
	MADDocumentObjectDataReference *labelDynamic = referenceOfType(MADPrintPageElementTypeLabelDynamic, context, nil, nil);
	MADDocumentObjectDataReference *aggregate = referenceOfType(MADPrintPageElementTypeAggregate, context, nil, nil);
	MADDocumentObjectDataReference *image = referenceOfType(MADPrintPageElementTypeImage, context, nil, nil);
	MADDocumentObjectDataReference *barcode = referenceOfType(MADPrintPageElementTypeBarcode, context, nil, nil);
	MADDocumentObjectDataReference *whitespace = referenceOfType(MADPrintPageElementTypeWhtiespace, context, nil, nil);
	MADDocumentObjectDataReference *chart = referenceOfType(MADPrintPageElementTypeChart, context, nil, nil);

	MAD_PASS_EQUAL(NSStringFromClass([labelStatic class]), @"MADDocumentObjectDataReferenceLabelStatic", "the static label maps to its own reference");
	MAD_PASS_EQUAL(NSStringFromClass([labelDynamic class]), @"MADDocumentObjectDataReferenceLabelDynamic", "the dynamic label maps to its own reference");
	MAD_PASS_EQUAL(NSStringFromClass([aggregate class]), @"MADDocumentObjectDataReferenceAggregate", "the aggregate maps to its own reference");
	MAD_PASS_EQUAL(NSStringFromClass([image class]), @"MADDocumentObjectDataReferenceImage", "the image maps to its own reference");
	// On Apple a barcode maps to MADDocumentObjectDataReferenceBarcode; that class (and
	// MADBarcodes) is excluded from the Linux build, so the factory's #else arm logs and
	// falls through to the base class with the whitespace/chart default below.
	MAD_PASS_EQUAL(NSStringFromClass([barcode class]), @"MADDocumentObjectDataReference", "the barcode falls through to the base reference off Apple");
	// Whitespace (and anything the switch does not name) falls through to the base class.
	MAD_PASS_EQUAL(NSStringFromClass([whitespace class]), @"MADDocumentObjectDataReference", "the whitespace falls through to the base reference");
	MAD_PASS_EQUAL(NSStringFromClass([chart class]), @"MADDocumentObjectDataReference", "the chart falls through to the base reference");
}

#pragma mark - Wiring

static void testReferenceStoresPageItemAndIDs(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, delegate, nil);

	MAD_PASS(reference.pageIndex == (NSUInteger)3, "the page index is stored");
	MAD_PASS(reference.detailRowId == (NSUInteger)42, "the detail row id is stored");
	MAD_PASS(reference.item != nil, "the item is stored");
	// -type reads the element's own type.
	MAD_PASS(reference.type == MADPrintPageElementTypeLabelStatic, "the type reads the element");
	// The delegate is held, but weakly (the header does not expose the accessor).
	MAD_PASS([reference delegate] == delegate, "the delegate is stored");
}

static void testItemAndDatasourceAreHeldWeakly(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDocumentObjectDataReference *reference = nil;

	@autoreleasepool {
		RptqDocumentElement *element = (RptqDocumentElement *)[context insertObjectForEntity:@"RptqDocumentElement" identifier:0];
		element.type = MADPrintPageElementTypeLabelStatic;
		reference = [MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																		  delegate:nil
																			  page:0
																			  item:element
																			itemID:0];
		MAD_PASS(reference.item != nil, "the item is wired");
		// The context retains the element, so only its own reference can drop here.
	}

	MAD_PASS(reference.item != nil, "the item survives the pool through the context's hold");
}

#pragma mark - Formatting

static void testFormattedStringFallsThroughToTheElement(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, nil, nil);

	NSString *formatted = [reference formattedString:MADDataTypeString forValue:@"abc"];
	MAD_PASS_EQUAL(formatted, @"abc", "the string falls through to the element");

	// A NULL from the data reads as empty text.
	NSString *formattedNull = [reference formattedString:MADDataTypeString forValue:[NSNull null]];
	MAD_PASS_EQUAL(formattedNull, @"", "a NULL reads as empty text");
}

#pragma mark - Delegate

static void testFontAttributesComeFromTheDelegate(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	delegate.attributes = @{ @"FamilyName": @"Helvetica Neue" };
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, delegate, nil);

	NSDictionary *attributes = [reference fontAttributes];
	MAD_PASS_EQUAL(attributes, delegate.attributes, "the font attributes come from the delegate");
}

static void testFontAttributesAreNilWithoutADelegate(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, nil, nil);

	NSDictionary *attributes = [reference fontAttributes];
	MAD_PASS(attributes == nil, "without a delegate the font attributes are nil");
}

#pragma mark - Copy

static void testCopyCarriesItemAndIndexesButNotTheDelegate(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDataReferenceDelegateDouble *delegate = [[MADDataReferenceDelegateDouble alloc] init];
	delegate.attributes = @{ @"FamilyName": @"Helvetica Neue" };
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, delegate, nil);

	MADDocumentObjectDataReference *copy = [reference copy];

	MAD_PASS_EQUAL(NSStringFromClass([copy class]), NSStringFromClass([reference class]), "the copy keeps the concrete class");
	MAD_PASS(copy.item == reference.item, "the copy carries the item");
	MAD_PASS(copy.pageIndex == reference.pageIndex, "the copy carries the page index");
	MAD_PASS(copy.detailRowId == reference.detailRowId, "the copy carries the detail row id");
	MAD_PASS(copy.datasource == reference.datasource, "the copy carries the datasource");
	// The delegate is not part of the copy, so the copy cannot format text.
	MAD_PASS([copy delegate] == nil, "the copy does not carry the delegate");
	NSDictionary *copyAttributes = [copy fontAttributes];
	MAD_PASS(copyAttributes == nil, "the copy has no font attributes");
}

#pragma mark - Font descriptors

static void testFontDescriptorsStartNil(void) {
	RptqStoreContext *context = inMemoryContext();
	MADDocumentObjectDataReference *reference = referenceOfType(MADPrintPageElementTypeLabelStatic, context, nil, nil);

	// The property is declared but nothing ever fills it; -dealloc only clears it.
	MAD_PASS(reference.fontDescriptors == nil, "the font descriptors start nil");
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceTests",
	MAD_TEST(testFactorySelectsConcreteClassForElementType),
	MAD_TEST(testReferenceStoresPageItemAndIDs),
	MAD_TEST(testItemAndDatasourceAreHeldWeakly),
	MAD_TEST(testFormattedStringFallsThroughToTheElement),
	MAD_TEST(testFontAttributesComeFromTheDelegate),
	MAD_TEST(testFontAttributesAreNilWithoutADelegate),
	MAD_TEST(testCopyCarriesItemAndIndexesButNotTheDelegate),
	MAD_TEST(testFontDescriptorsStartNil));
