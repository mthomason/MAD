//
//  MADPrintPageElementBarcodeTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization tests for MADPrintPageElementBarcode: the element that turns a
//  MADDocumentObjectDataReferenceBarcode into an MADBarcode, copies the symbology
//  settings across, and forwards drawing to it.
//
//  MADTests does not link MADBarcodes (MAD.framework does, so MADBarcode is present at
//  runtime), so this file never imports the barcode headers.  The definition is a
//  double whose `barcode` is a duck-typed object with MADBarcodeProtocol's property
//  names, and the created MADBarcode is inspected through KVC.
//
//  The type-8 double is Code 39 (zint's BARCODE_CODE39), whose class initialiser needs
//  no input; type 0 is not a case in +newBarcodeWithType:, so the factory returns nil.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "MADDocumentObjectType.h"
#import "MADPrintPageElement.h"
#import "MADPrintPageElement+Constructor.h"
#import "MADPrintPageElementBarcode.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADReportLineRepresentation.h"

// MADBarcodes is not linked here, so the protocol only needs to be named, not defined.
@protocol MADBarcodeProtocol;

#pragma mark - Test doubles

// Everything MADPrintPageRendererDataSourceProtocol requires; only -dataForRow:error:
// is asked for by the element.
@interface MADBarcodeElementTestSource : NSObject <MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@property (nonatomic, strong) NSDictionary *rowData;
@property (nonatomic, assign) NSUInteger lastRowID;
@property (nonatomic, strong) NSError *reportedError;

@end

@implementation MADBarcodeElementTestSource

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID { return @[]; }
- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber { return @[]; }
- (NSArray <NSString *> *)groupLevelKeyNames { return @[]; }

- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID
												 error:(NSError * __autoreleasing *)error {
	self.lastRowID = rowID;
	if (error != NULL) {
		*error = self.reportedError;
	}
	return self.rowData;
}

- (NSDictionary *)dataForRowReportFirst { return nil; }
- (NSDictionary *)dataForRowReportLast { return nil; }
- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex { return nil; }
- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID column:(NSString *)columnKey error:(NSError * __autoreleasing *)error { return nil; }
- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys groupID:(int64_t)groupID { return @[]; }
- (__kindof NSObject <NSCopying> *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy { return nil; }
- (NSUInteger)rowIDFirstOfReport { return 1; }
- (NSUInteger)rowIDLastOfReport { return 1; }
- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page { return 1; }
- (NSUInteger)rowIDLastOfPage:(NSUInteger)page { return 1; }
- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex { return @[]; }
- (void)updatePrintingReportFormatter { }

@end

// A duck-typed stand-in for RptqDocumentElementBarcode, which is what the real
// reference returns from -barcode.  MADBarcode reads only these properties from it.
@interface MADBarcodeElementTestBarcode : NSObject

@property (nonatomic, assign) int16_t barcodeType;
@property (nonatomic, assign) int16_t barcodeBorderStyle;
@property (nonatomic, assign) int16_t whitespaceWidth;
@property (nonatomic, assign) BOOL has2dComponentEnabled;
@property (nonatomic, assign) int16_t barcodeBorderWidth;
@property (nonatomic, assign) int16_t barcodeHeight;
@property (nonatomic, assign) BOOL humanReadable;
@property (nonatomic, assign) int16_t option1;
@property (nonatomic, assign) int16_t option2;
@property (nonatomic, assign) int16_t option3;
@property (nonatomic, assign) BOOL showErrorMessage;
@property (nonatomic, assign) float scale;

@end

@implementation MADBarcodeElementTestBarcode
@end

// The definition double: only these selectors are read by the element.  Values handed
// to the two formatting hooks are recorded so the tests can see what was passed.
@interface MADBarcodeElementTestDefinition : MADDocumentObjectDataReferenceBarcode

@property (nonatomic, strong) NSObject <MADPrintPageRendererDataSourceProtocol> *testDatasource;
@property (nonatomic, copy) NSString *testFieldKey1;
@property (nonatomic, copy) NSString *testFieldKey2;
@property (nonatomic, strong) MADBarcodeElementTestBarcode *testBarcode;
@property (nonatomic, assign) MADPrintPageElementType testType;
@property (nonatomic, copy) NSString *nilValueSpelling;

@property (nonatomic, strong) id firstValueSeen;
@property (nonatomic, strong) id secondValueSeen;

@end

@implementation MADBarcodeElementTestDefinition

- (NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource { return self.testDatasource; }
- (NSString *)fieldKey1 { return self.testFieldKey1; }
- (NSString *)fieldKey2 { return self.testFieldKey2; }
- (MADPrintPageElementType)type { return self.testType; }
- (id <MADBarcodeProtocol>)barcode { return (id <MADBarcodeProtocol>)self.testBarcode; }

- (NSString *)formattedStringForValue1:(id)value {
	self.firstValueSeen = value;
	return value != nil ? [value description] : (self.nilValueSpelling ?: @"");
}

- (NSString *)formattedStringForValue2:(id)value {
	self.secondValueSeen = value;
	return value != nil ? [value description] : (self.nilValueSpelling ?: @"");
}

@end

#pragma mark - Tests

@interface MADPrintPageElementBarcodeTests : XCTestCase
@end

@implementation MADPrintPageElementBarcodeTests

- (MADBarcodeElementTestDefinition *)definitionWithFields {
	MADBarcodeElementTestDefinition *definition = [[MADBarcodeElementTestDefinition alloc] init];
	definition.testDatasource = [[MADBarcodeElementTestSource alloc] init];
	definition.testFieldKey1 = @"Invoice0.Code";
	definition.testFieldKey2 = @"Invoice0.Note";
	definition.testBarcode = [[MADBarcodeElementTestBarcode alloc] init];
	definition.testType = MADPrintPageElementTypeBarcode;
	definition.detailRowId = 7;
	return definition;
}

#pragma mark - Construction

- (void)testBarcodeElementIsTheClassTheFactoryReturns {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];

	MADPrintPageElement *element = [MADPrintPageElement newDocumentObject:definition];

	XCTAssertEqualObjects(NSStringFromClass([element class]), @"MADPrintPageElementBarcode");
}

- (void)testBarcodeElementBuildsTheDrawingObjectFromTheRowValues {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = @{ @"Invoice0.Code" : @"123456", @"Invoice0.Note" : @"note" };

	// Code 39 -- MADBarcode +newBarcodeWithType: supports it, so a real object comes back.
	definition.testBarcode.barcodeType = 8;
	definition.testBarcode.scale = 1.5f;
	definition.testBarcode.humanReadable = YES;

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	// The row was read for the definition's detail row, and each field key was used.
	XCTAssertEqual(source.lastRowID, (NSUInteger)7);
	XCTAssertEqualObjects(definition.firstValueSeen, @"123456");
	XCTAssertEqualObjects(definition.secondValueSeen, @"note");

	NSObject *drawing = [element valueForKey:@"_drawingObject"];
	XCTAssertNotNil(drawing);
	XCTAssertEqual([(NSNumber *)[drawing valueForKey:@"barcodeType"] integerValue], (NSInteger)8);
	XCTAssertEqualObjects([drawing valueForKey:@"input"], @"123456");
	XCTAssertEqualObjects([drawing valueForKey:@"primaryData"], @"note");

	// The symbology settings were copied off the document element.
	XCTAssertEqualWithAccuracy([(NSNumber *)[drawing valueForKey:@"scale"] floatValue], 1.5f, 0.0001f);
	XCTAssertTrue([(NSNumber *)[drawing valueForKey:@"humanReadable"] boolValue]);
}

- (void)testBarcodeElementWithoutRowDataPassesNilValuesToFormatting {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = nil;

	definition.nilValueSpelling = @"(missing)";
	definition.testBarcode.barcodeType = 8;

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	// A nil row means both lookup values are nil, and nil is what the formatting hooks
	// are handed -- the element itself never substitutes a string.
	XCTAssertNil(definition.firstValueSeen);
	XCTAssertNil(definition.secondValueSeen);

	NSObject *drawing = [element valueForKey:@"_drawingObject"];
	XCTAssertNotNil(drawing);
	XCTAssertEqualObjects([drawing valueForKey:@"input"], @"(missing)");
	XCTAssertEqualObjects([drawing valueForKey:@"primaryData"], @"(missing)");
}

- (void)testBarcodeElementWithUnsupportedTypeHasNoDrawingObject {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	definition.testBarcode.barcodeType = 0; // no case in +newBarcodeWithType:

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	// +newBarcodeWithType: answered nil, so +newBarcode:input1:input2: answered nil and
	// the element holds nothing.
	XCTAssertNil([element valueForKey:@"_drawingObject"]);
	// Drawing forwards to nil, which is a no-op.
	[element drawInRect:CGRectMake(0.0, 0.0, 50.0, 20.0)];
}

- (void)testBarcodeElementDrawForwardsToTheDrawingObject {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = @{ @"Invoice0.Code" : @"ABC123", @"Invoice0.Note" : @"N" };
	definition.testBarcode.barcodeType = 8;
	// A sane module height keeps the zint encode on its normal path.
	definition.testBarcode.barcodeHeight = 50;

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];
	XCTAssertNotNil([element valueForKey:@"_drawingObject"]);

	// Drawing a real Code 39 barcode needs the zint context; the element's own contract
	// is only that it does not stash state of its own, so drawing into an image context
	// is enough to show the forward does not throw.
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(80.0, 30.0), NO, 1.0);
	[element drawInRect:CGRectMake(0.0, 0.0, 80.0, 30.0)];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	XCTAssertNotNil(image);
}

#pragma mark - Text

- (void)testBarcodeElementCarriesTheComposedInputAsText {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = @{ @"Invoice0.Code" : @"123456", @"Invoice0.Note" : @"note" };
	definition.testBarcode.barcodeType = 8;

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"123456note");

	// The line representation already reads -text from a text-shaped drawing object, so
	// the barcode line reaches every exporter and the accessibility walk through it.
	MADReportLineRepresentation *line;
	line = [[MADReportLineRepresentation alloc] initWithObject:element
														 type:MADPrintPageElementTypeBarcode
														frame:CGRectMake(0.0, 0.0, 80.0, 30.0)];
	XCTAssertEqualObjects(line.text, @"123456note");
}

- (void)testBarcodeElementTextOmitsAnAbsentSecondInput {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = @{ @"Invoice0.Code" : @"123456" };
	definition.testBarcode.barcodeType = 8;

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	XCTAssertEqualObjects(element.text, @"123456");
}

#pragma mark - Logging contract

- (void)testBarcodeElementStillBuildsWhenTheDataSourceReportsAnError {
	MADBarcodeElementTestDefinition *definition = [self definitionWithFields];
	MADBarcodeElementTestSource *source = (MADBarcodeElementTestSource *)definition.testDatasource;
	source.rowData = @{ @"Invoice0.Code" : @"X", @"Invoice0.Note" : @"Y" };
	definition.testBarcode.barcodeType = 0;

	// The element always passes a valid NSError** down; the source handing an error
	// back only produces a log line, never a change in the built object.
	source.reportedError = [NSError errorWithDomain:@"MADBarcodeElementTest" code:1 userInfo:nil];

	MADPrintPageElementBarcode *element;
	element = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];

	XCTAssertNil([element valueForKey:@"_drawingObject"]);
}

@end
