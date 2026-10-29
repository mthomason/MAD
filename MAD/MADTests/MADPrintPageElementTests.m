//
//  MADPrintPageElementTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization tests for the print-page element cluster that MADPrintPageRenderer
//  builds per document element:
//
//    * MADPrintPageElement            -- the base: keeps nothing, draws nothing.
//    * MADPrintPageElementText        -- draws its text with the definition's font
//                                        attributes.
//    * MADPrintPageElementTextStatic  -- copies its text once, from the definition.
//    * MADPrintPageElementTextDynamic -- reads its text from the data source, keyed by
//                                        the definition's fieldKey.
//    * MADPrintPageElementImage       -- adopts the definition's image.
//    * MADPrintPageElementAggregate   -- the calculate-in-memory First/Last paths, the
//                                        datasource-backed path, and the
//                                        "Error: No Datasource" placeholder.
//    * MADPrintPageElement (Constructor) -- the type -> class factory.
//
//  The static-label, image and factory cases run against real store-backed document
//  elements; the dynamic and aggregate cases use definition doubles, because a real
//  RptqDocumentElementLabelDataField / RptqDocumentElementAggregate needs a query, a
//  group and a populated cache, while the elements only read a handful of selectors
//  off the definition.
//

#include <TargetConditionals.h>
#import <XCTest/XCTest.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
typedef NSFont MADElementTestFont;
#else
#import <UIKit/UIFont.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSAttributedString.h>
typedef UIFont MADElementTestFont;
#endif
#import <CoreGraphics/CGContext.h>
#import <CoreGraphics/CGImage.h>

#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectType.h"
#import "MADPrintPageElement.h"
#import "MADPrintPageElement+Constructor.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADStore.h"
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabel.h"
#import "RptqStoreContext.h"

#pragma mark - Test doubles

// The element-facing half of MADPrintPageRendererDataSourceProtocol, with the answers
// the tests set and the arguments the elements passed recorded back.  The protocol's
// other members are implemented too, so the double is a genuinely conforming class.
@interface MADPrintTestDataSource : NSObject <MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

// Answers
@property (nonatomic, strong) id columnValue;
@property (nonatomic, assign) BOOL answerNoRowData;
@property (nonatomic, strong) NSArray <NSDictionary *> *dataForGroupsRows;
@property (nonatomic, strong) NSDictionary *pageFirstRow;
@property (nonatomic, strong) NSDictionary *pageLastRow;
@property (nonatomic, strong) NSDictionary *reportFirstRow;
@property (nonatomic, strong) NSDictionary *reportLastRow;
@property (nonatomic, strong) NSArray <NSNumber *> *rowIDsForPageAnswer;
@property (nonatomic, strong) id aggregateResult;
@property (nonatomic, strong) NSArray *groupKeysAnswer;

// Recorders
@property (nonatomic, assign) NSUInteger lastRowID;
@property (nonatomic, copy) NSString *lastColumnKey;
@property (nonatomic, assign) int64_t lastGroupKeysRowID;
@property (nonatomic, assign) int64_t lastGroupNumber;
@property (nonatomic, assign) NSUInteger lastRowIDsPage;
@property (nonatomic, copy) NSString *lastDataForRowsColumn;
@property (nonatomic, strong) NSArray *lastDataForRowsGroups;
@property (nonatomic, assign) MTAggregateFunctionType lastDataForRowsFunction;
@property (nonatomic, assign) MTAggregateGroupByType lastDataForRowsGroupBy;
@property (nonatomic, assign) NSUInteger lastPageFirstIndex;
@property (nonatomic, assign) NSUInteger lastPageLastIndex;

@end

@implementation MADPrintTestDataSource

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID {
	return @[];
}

- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber {
	self.lastGroupKeysRowID = rowID;
	self.lastGroupNumber = groupNumber;
	return self.groupKeysAnswer ?: @[];
}

- (NSArray <NSString *> *)groupLevelKeyNames {
	return @[];
}

- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID
												 error:(NSError * __autoreleasing *)error {
	self.lastRowID = rowID;
	return self.answerNoRowData ? nil : @{};
}

- (NSDictionary *)dataForRowReportFirst {
	return self.reportFirstRow;
}

- (NSDictionary *)dataForRowReportLast {
	return self.reportLastRow;
}

- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex {
	self.lastPageFirstIndex = pageIndex;
	return self.pageFirstRow;
}

- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex {
	self.lastPageLastIndex = pageIndex;
	return self.pageLastRow;
}

- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID
												column:(NSString *)columnKey
												 error:(NSError * __autoreleasing *)error {
	self.lastRowID = rowID;
	self.lastColumnKey = columnKey;
	if (self.answerNoRowData) {
		return nil;
	}
	return columnKey != nil && self.columnValue != nil ? @{ columnKey : self.columnValue } : @{};
}

- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys
											 groupID:(int64_t)groupID {
	return self.dataForGroupsRows ?: @[];
}

- (__kindof NSObject <NSCopying> *)dataForRows:(NSArray *)rowIDs
										column:(NSString *)columnKey
										groups:(NSArray *)groupKeys
									  function:(MTAggregateFunctionType)function
									   groupBy:(MTAggregateGroupByType)groupBy {
	self.lastDataForRowsColumn = columnKey;
	self.lastDataForRowsGroups = groupKeys;
	self.lastDataForRowsFunction = function;
	self.lastDataForRowsGroupBy = groupBy;
	return self.aggregateResult;
}

- (NSUInteger)rowIDFirstOfReport { return 1; }
- (NSUInteger)rowIDLastOfReport { return 1; }
- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page { return 1; }
- (NSUInteger)rowIDLastOfPage:(NSUInteger)page { return 1; }

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex {
	self.lastRowIDsPage = pageIndex;
	return self.rowIDsForPageAnswer ?: @[];
}

- (void)updatePrintingReportFormatter { }

@end

// A definition double for the types whose real reference needs a query graph: the
// element asks it for exactly these selectors.  It subclasses the real reference so
// the factory's casts stay honest.
@interface MADPrintTestDefinition : MADDocumentObjectDataReference

@property (nonatomic, assign) MADPrintPageElementType testType;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) MADReferenceImage *image;
@property (nonatomic, copy) NSString *fieldKey;
@property (nonatomic, strong) NSObject <MADPrintPageRendererDataSourceProtocol> *testDatasource;
@property (nonatomic, assign) BOOL calculateInMemory;
@property (nonatomic, assign) MTAggregateGroupByType testGroupType;
@property (nonatomic, assign) MTAggregateFunctionType testFunctionType;
@property (nonatomic, assign) int32_t testGroupNumber;

@end

@implementation MADPrintTestDefinition

- (MADPrintPageElementType)type { return self.testType; }
- (NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource { return self.testDatasource; }
- (MTAggregateGroupByType)groupType { return self.testGroupType; }
- (MTAggregateFunctionType)functionType { return self.testFunctionType; }
- (int32_t)groupNumber { return self.testGroupNumber; }

- (NSString *)formattedStringForValue:(id)value {
	return value != nil ? [value description] : @"";
}

@end

// The dynamic-label double: only fieldKey, datasource and the formatter are read.
@interface MADPrintTestDynamicDefinition : MADDocumentObjectDataReferenceLabelDynamic

@property (nonatomic, copy) NSString *testFieldKey;
@property (nonatomic, strong) NSObject <MADPrintPageRendererDataSourceProtocol> *testDatasource;
@property (nonatomic, copy) NSString *formattedPrefix;

@end

@implementation MADPrintTestDynamicDefinition

- (NSString *)fieldKey { return self.testFieldKey; }
- (NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource { return self.testDatasource; }

- (NSString *)formattedStringForValue:(id)value {
	NSString *prefix = self.formattedPrefix ?: @"formatted:";
	return [prefix stringByAppendingString:value != nil ? [value description] : @"nil"];
}

@end

// The aggregate double: the element reads the group knobs and formats the result.
@interface MADPrintTestAggregateDefinition : MADDocumentObjectDataReferenceAggregate

@property (nonatomic, copy) NSString *testFieldKey;
@property (nonatomic, strong) NSObject <MADPrintPageRendererDataSourceProtocol> *testDatasource;
@property (nonatomic, assign) int32_t testGroupNumber;
@property (nonatomic, assign) MTAggregateGroupByType testGroupType;
@property (nonatomic, assign) MTAggregateFunctionType testFunctionType;
@property (nonatomic, assign) BOOL testCalculateInMemory;

@end

@implementation MADPrintTestAggregateDefinition

- (NSString *)fieldKey { return self.testFieldKey; }
- (NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource { return self.testDatasource; }
- (int32_t)groupNumber { return self.testGroupNumber; }
- (MTAggregateGroupByType)groupType { return self.testGroupType; }
- (MTAggregateFunctionType)functionType { return self.testFunctionType; }
- (BOOL)calculateInMemory { return self.testCalculateInMemory; }

- (NSString *)formattedStringForValue:(id)value {
	return value != nil ? [value description] : @"";
}

@end

#pragma mark - Tests

// The delegate side of the factory: the elements that draw text ask their definition
// for font attributes, and the definition forwards that to its delegate.
@interface MADPrintPageElementTests : XCTestCase <MADDocumentObjectDataReferenceProtocol>

@property (nonatomic, strong) NSDictionary <NSString *, id> *testFontAttributes;

@end

@implementation MADPrintPageElementTests

- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef {
	if (self.testFontAttributes == nil) {
		self.testFontAttributes = @{ NSFontAttributeName : [MADElementTestFont systemFontOfSize: 12.0] };
	}
	return self.testFontAttributes;
}

#pragma mark - Fixtures

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

// The two images are the same picture when both redraw to the same pixels in one
// common format.  PNG bytes are not stable across a decode/re-encode, so comparing
// the encodings would fail on the encoding, not the picture.
- (NSData *)redrawnPixelsOfImage:(MADReferenceImage *)image {
#if TARGET_OS_OSX
	CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
#else
	CGImageRef cgImage = image.CGImage;
#endif
	if (!cgImage) return nil;
	size_t width = CGImageGetWidth(cgImage), height = CGImageGetHeight(cgImage);
	if (width == 0 || height == 0) return nil;
	NSMutableData *pixels = [NSMutableData dataWithLength:width * height * 4];
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, width, height, 8, width * 4, space,
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(space);
	if (!context) return nil;
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
	CGContextRelease(context);
	return pixels;
}

- (MADDocumentObjectDataReference *)referenceForElement:(__kindof RptqDocumentElement *)element
												dataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)dataSource {
	MADDocumentObjectDataReference *reference;
	reference = [MADDocumentObjectDataReference newDocumentObjectDataReference:dataSource
																	  delegate:self
																		  page:0
																		  item:element
																		itemID:7];
	return reference;
}

#pragma mark - Base element

- (void)testBaseElementInitIgnoresItsDefinition {
	MADPrintTestDefinition *definition = [[MADPrintTestDefinition alloc] init];
	MADPrintPageElement *element = [[MADPrintPageElement alloc] initWithDefinition:definition];

	XCTAssertNotNil(element);
	XCTAssertEqualObjects(NSStringFromClass([element class]), @"MADPrintPageElement");
	// The base draw is empty; it is safe to call with no graphics context at all.
	[element drawInRect:CGRectMake(0.0, 0.0, 10.0, 10.0)];
}

#pragma mark - MADPrintPageElementText

- (void)testTextElementStartsEmptyAndKeepsAnAssignedText {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	MADPrintTestDefinition *definition = [[MADPrintTestDefinition alloc] init];
	definition.testDatasource = source;

	MADPrintPageElementText *element = [[MADPrintPageElementText alloc] initWithDefinition:definition];
	XCTAssertNil(element.text);

	element.text = @"typed";
	XCTAssertEqualObjects(element.text, @"typed");
}

- (void)testTextElementDrawInRectUsesTheDefinitionsFontAttributes {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	MADPrintTestDefinition *definition = [[MADPrintTestDefinition alloc] init];
	definition.testDatasource = source;
	// The real reference forwards -fontAttributes to its delegate; point the double at
	// this test case so the draw reads the same kind of dictionary production hands it.
	[definition setValue:self forKey:@"delegate"];

	MADPrintPageElementText *element = [[MADPrintPageElementText alloc] initWithDefinition:definition];
	element.text = @"Hello";

#if TARGET_OS_OSX
	NSImage *canvas = [[NSImage alloc] initWithSize:NSMakeSize(60.0, 20.0)];
	[canvas lockFocus];
	[element drawInRect:CGRectMake(0.0, 0.0, 60.0, 20.0)];
	[canvas unlockFocus];
	XCTAssertNotNil(canvas);
#else
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(60.0, 20.0), NO, 1.0);
	[element drawInRect:CGRectMake(0.0, 0.0, 60.0, 20.0)];
	UIImage *canvas = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	XCTAssertNotNil(canvas);
#endif
}

#pragma mark - MADPrintPageElementTextStatic

- (void)testStaticLabelElementCopiesDefinitionText {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabel *label;
	label = (RptqDocumentElementLabel *)[context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:0];
	label.type = (int16_t)MADPrintPageElementTypeLabelStatic;
	label.text = @"Invoice";

	MADDocumentObjectDataReference *reference = [self referenceForElement:label dataSource:nil];
	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceLabelStatic");

	MADPrintPageElement *element = [MADPrintPageElement newDocumentObject:reference];

	XCTAssertEqualObjects(NSStringFromClass([element class]), @"MADPrintPageElementTextStatic");
	XCTAssertEqualObjects(((MADPrintPageElementText *)element).text, @"Invoice");
	// The element took a copy; mutating the definition afterwards changes nothing.
	label.text = @"Changed";
	XCTAssertEqualObjects(((MADPrintPageElementText *)element).text, @"Invoice");
}

- (void)testStaticLabelDrawInRectInheritsTheTextDraw {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabel *label;
	label = (RptqDocumentElementLabel *)[context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:0];
	label.type = (int16_t)MADPrintPageElementTypeLabelStatic;
	label.text = @"Hello";

	MADDocumentObjectDataReference *reference = [self referenceForElement:label dataSource:nil];
	MADPrintPageElement *element = [MADPrintPageElement newDocumentObject:reference];

#if TARGET_OS_OSX
	NSImage *canvas = [[NSImage alloc] initWithSize:NSMakeSize(60.0, 20.0)];
	[canvas lockFocus];
	[element drawInRect:CGRectMake(0.0, 0.0, 60.0, 20.0)];
	[canvas unlockFocus];
	XCTAssertNotNil(canvas);
#else
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(60.0, 20.0), NO, 1.0);
	[element drawInRect:CGRectMake(0.0, 0.0, 60.0, 20.0)];
	UIImage *canvas = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	XCTAssertNotNil(canvas);
#endif
}

#pragma mark - MADPrintPageElementTextDynamic

- (void)testDynamicLabelFormatsTheColumnValueFromTheDataSource {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.columnValue = @42;

	MADPrintTestDynamicDefinition *definition = [[MADPrintTestDynamicDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.detailRowId = 9;

	MADPrintPageElementTextDynamic *element;
	element = [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"formatted:42");
	XCTAssertEqual(source.lastRowID, (NSUInteger)9);
	XCTAssertEqualObjects(source.lastColumnKey, @"Invoice0.Total");
}

- (void)testDynamicLabelWithoutRowDataFallsBackToEmptyString {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.answerNoRowData = YES;

	MADPrintTestDynamicDefinition *definition = [[MADPrintTestDynamicDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";

	MADPrintPageElementTextDynamic *element;
	element = [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];

	// No row -> the text stays @"" and the formatter is never reached.
	XCTAssertEqualObjects(element.text, @"");
}

- (void)testDynamicLabelWithNilValueUsesTheEmptyString {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	// The row exists but does not carry the field key; the value reads back nil.
	source.columnValue = nil;

	MADPrintTestDynamicDefinition *definition = [[MADPrintTestDynamicDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";

	MADPrintPageElementTextDynamic *element;
	element = [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"");
}

#pragma mark - MADPrintPageElementImage

- (void)testImageElementAdoptsTheDefinitionImage {
	RptqStoreContext *context = [self inMemoryContext];

#if TARGET_OS_OSX
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																	pixelsWide:2
																	pixelsHigh:2
																 bitsPerSample:8
															   samplesPerPixel:4
																	  hasAlpha:YES
																	  isPlanar:NO
																colorSpaceName:NSCalibratedRGBColorSpace
																   bytesPerRow:8
																  bitsPerPixel:32];
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(2.0, 2.0)];
	[image addRepresentation:rep];
#else
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(2.0, 2.0), NO, 1.0);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
#endif
	XCTAssertNotNil(image);

	RptqDocumentElementImage *element;
	element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = (int16_t)MADPrintPageElementTypeImage;
	element.image = image;

	MADDocumentObjectDataReference *reference = [self referenceForElement:element dataSource:nil];
	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceImage");

	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:reference];
	XCTAssertEqualObjects(NSStringFromClass([drawingObject class]), @"MADPrintPageElementImage");
	// The element adopts the definition's picture.  The image reaches it through the
	// store's PNG wire format, so it is the same picture, not the same object.
	id adopted = [drawingObject valueForKey:@"image"];
	XCTAssertTrue([adopted isKindOfClass:[MADReferenceImage class]]);
	XCTAssertTrue(CGSizeEqualToSize(((MADReferenceImage *)adopted).size, image.size));
	XCTAssertEqualObjects([self redrawnPixelsOfImage:adopted], [self redrawnPixelsOfImage:image]);

#if TARGET_OS_OSX
	NSImage *canvas = [[NSImage alloc] initWithSize:NSMakeSize(4.0, 4.0)];
	[canvas lockFocus];
	[drawingObject drawInRect:CGRectMake(0.0, 0.0, 4.0, 4.0)];
	[canvas unlockFocus];
#else
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(4.0, 4.0), NO, 1.0);
	[drawingObject drawInRect:CGRectMake(0.0, 0.0, 4.0, 4.0)];
	UIGraphicsEndImageContext();
#endif
}

- (void)testImageElementWithNoItemImageDrawsNothing {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementImage *item;
	item = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	item.type = (int16_t)MADPrintPageElementTypeImage;

	MADDocumentObjectDataReference *reference = [self referenceForElement:item dataSource:nil];
	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:reference];

	XCTAssertNil([drawingObject valueForKey:@"image"]);
	[drawingObject drawInRect:CGRectMake(0.0, 0.0, 4.0, 4.0)];
}

#pragma mark - MADPrintPageElementAggregate

- (void)testAggregateWithoutDefinitionReportsTheNoDatasourcePlaceholder {
	MADPrintPageElementAggregate *element;
	element = [[MADPrintPageElementAggregate alloc] initWithDefinition:nil];

	XCTAssertEqualObjects(element.text, @"Error: No Datasource");
}

- (void)testAggregateWithoutDatasourceReportsTheNoDatasourcePlaceholder {
	MADDocumentObjectDataReferenceAggregate *definition;
	definition = [[MADDocumentObjectDataReferenceAggregate alloc] init];
	definition.detailRowId = 4;

	MADPrintPageElementAggregate *element;
	element = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"Error: No Datasource");
}

- (void)testAggregateInMemoryFirstAndLastOfSection {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.groupKeysAnswer = @[ @"GroupKey" ];
	source.dataForGroupsRows = @[ @{ @"Invoice0.Total" : @1 }, @{ @"Invoice0.Total" : @2 } ];

	MADPrintTestAggregateDefinition *definition = [[MADPrintTestAggregateDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.testCalculateInMemory = YES;
	definition.testGroupType = MTAggregateGroupByTypeSection;
	definition.detailRowId = 11;
	definition.testGroupNumber = 2;

	definition.testFunctionType = MTAggregateFunctionTypeFirst;
	MADPrintPageElementAggregate *first;
	first = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(first.text, @"1");
	// The section value is fetched for the definition's row and group.
	XCTAssertEqual(source.lastGroupKeysRowID, (int64_t)11);
	XCTAssertEqual(source.lastGroupNumber, (int64_t)2);

	definition.testFunctionType = MTAggregateFunctionTypeLast;
	MADPrintPageElementAggregate *last;
	last = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(last.text, @"2");
}

- (void)testAggregateInMemorySectionWithOtherFunctionsUsesTheEmptyValue {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.groupKeysAnswer = @[ @"GroupKey" ];
	// The rows are deliberately distinct so a fall-through to a row value would show.
	source.dataForGroupsRows = @[ @{ @"Invoice0.Total" : @1 }, @{ @"Invoice0.Total" : @2 } ];

	MADPrintTestAggregateDefinition *definition = [[MADPrintTestAggregateDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.testCalculateInMemory = YES;
	definition.testGroupType = MTAggregateGroupByTypeSection;
	definition.testFunctionType = MTAggregateFunctionTypeSum;

	MADPrintPageElementAggregate *element;
	element = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	// Only First and Last have an in-memory implementation; everything else formats
	// the placeholder empty string the switch plants in the dictionary.
	XCTAssertEqualObjects(element.text, @"");
}

- (void)testAggregateInMemoryFirstAndLastOfPage {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.groupKeysAnswer = @[ @"GroupKey" ];
	source.pageFirstRow = @{ @"Invoice0.Total" : @10 };
	source.pageLastRow = @{ @"Invoice0.Total" : @20 };

	MADPrintTestAggregateDefinition *definition = [[MADPrintTestAggregateDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.testCalculateInMemory = YES;
	definition.testGroupType = MTAggregateGroupByTypePage;
	definition.pageIndex = 5;

	definition.testFunctionType = MTAggregateFunctionTypeFirst;
	MADPrintPageElementAggregate *first;
	first = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(first.text, @"10");
	XCTAssertEqual(source.lastPageFirstIndex, (NSUInteger)5);

	definition.testFunctionType = MTAggregateFunctionTypeLast;
	MADPrintPageElementAggregate *last;
	last = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(last.text, @"20");
	XCTAssertEqual(source.lastPageLastIndex, (NSUInteger)5);
}

- (void)testAggregateInMemoryFirstAndLastOfReport {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.groupKeysAnswer = @[ @"GroupKey" ];
	source.reportFirstRow = @{ @"Invoice0.Total" : @100 };
	source.reportLastRow = @{ @"Invoice0.Total" : @200 };

	MADPrintTestAggregateDefinition *definition = [[MADPrintTestAggregateDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.testCalculateInMemory = YES;
	definition.testGroupType = MTAggregateGroupByTypeReport;

	definition.testFunctionType = MTAggregateFunctionTypeFirst;
	MADPrintPageElementAggregate *first;
	first = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];
	XCTAssertEqualObjects(first.text, @"100");

	definition.testFunctionType = MTAggregateFunctionTypeLast;
	MADPrintPageElementAggregate *last;
	last = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];
	XCTAssertEqualObjects(last.text, @"200");
}

- (void)testAggregateOutsideMemoryReadsTheCacheThroughTheDatasource {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	source.groupKeysAnswer = @[ @"GroupKey" ];
	source.rowIDsForPageAnswer = @[ @1, @2, @3 ];
	source.aggregateResult = @99;

	MADPrintTestAggregateDefinition *definition = [[MADPrintTestAggregateDefinition alloc] init];
	definition.testDatasource = source;
	definition.testFieldKey = @"Invoice0.Total";
	definition.testCalculateInMemory = NO;
	definition.testGroupType = MTAggregateGroupByTypeSection;
	definition.testFunctionType = MTAggregateFunctionTypeSum;
	definition.pageIndex = 3;
	definition.testGroupNumber = 1;
	definition.detailRowId = 8;

	MADPrintPageElementAggregate *element;
	element = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"99");
	XCTAssertEqual(source.lastRowIDsPage, (NSUInteger)3);
	XCTAssertEqual(source.lastGroupKeysRowID, (int64_t)8);
	XCTAssertEqual(source.lastGroupNumber, (int64_t)1);
	XCTAssertEqualObjects(source.lastDataForRowsColumn, @"Invoice0.Total");
	XCTAssertEqualObjects(source.lastDataForRowsGroups, (@[ @"GroupKey" ]));
	XCTAssertEqual(source.lastDataForRowsFunction, MTAggregateFunctionTypeSum);
	XCTAssertEqual(source.lastDataForRowsGroupBy, MTAggregateGroupByTypeSection);
}

#pragma mark - MADPrintPageElement (Constructor)

- (void)testFactoryMapsTypesToConcreteElements {
	MADPrintTestDataSource *source = [[MADPrintTestDataSource alloc] init];
	MADPrintTestDefinition *definition = [[MADPrintTestDefinition alloc] init];
	definition.testDatasource = source;
	definition.text = @"static";
	definition.fieldKey = @"Invoice0.Total";

	definition.testType = MADPrintPageElementTypeLabelStatic;
	XCTAssertEqualObjects(NSStringFromClass([[MADPrintPageElement newDocumentObject:definition] class]),
						  @"MADPrintPageElementTextStatic");

	definition.testType = MADPrintPageElementTypeLabelDynamic;
	XCTAssertEqualObjects(NSStringFromClass([[MADPrintPageElement newDocumentObject:definition] class]),
						  @"MADPrintPageElementTextDynamic");

	definition.testType = MADPrintPageElementTypeImage;
	XCTAssertEqualObjects(NSStringFromClass([[MADPrintPageElement newDocumentObject:definition] class]),
						  @"MADPrintPageElementImage");

	definition.testType = MADPrintPageElementTypeAggregate;
	XCTAssertEqualObjects(NSStringFromClass([[MADPrintPageElement newDocumentObject:definition] class]),
						  @"MADPrintPageElementAggregate");
}

- (void)testFactoryReturnsNilForUnsupportedTypes {
	MADPrintTestDefinition *definition = [[MADPrintTestDefinition alloc] init];

	NSArray <NSNumber *> *unsupported = @[ @(MADPrintPageElementTypeChart),
										   @(MADPrintPageElementTypeFormula),
										   @(MADPrintPageElementTypeGroupKey),
										   @(MADPrintPageElementTypeAggregateFunctionList),
										   @(MADPrintPageElementTypeWhtiespace),
										   @(MADPrintPageElementTypeLabelLink),
										   @((MADPrintPageElementType)99) ];
	for (NSNumber *type in unsupported) {
		definition.testType = (MADPrintPageElementType)type.integerValue;
		XCTAssertNil([MADPrintPageElement newDocumentObject:definition],
					 @"type %@ should have no element", type);
	}
}

@end
