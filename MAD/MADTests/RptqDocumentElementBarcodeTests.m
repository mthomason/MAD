//
//  RptqDocumentElementBarcodeTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The barcode element's model invariants: the factory stores the symbology in
//  `barcodeType` and leaves the base `type` at MADPrintPageElementTypeBarcode, the
//  update path keeps that invariant, and the element's two colours map through the
//  store's four component columns each.
//
//  MADTests does not link MADBarcodes (MAD.framework does, so the real class is
//  present at runtime), so the factory argument is a duck-typed double with the
//  MADBarcode property names; the barcode headers are never imported here.
//

#include <TargetConditionals.h>
#import <XCTest/XCTest.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIColor.h>
#endif

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqDocumentElement+Extras.h"

@class MADBarcode;

/// The properties the two barcode paths read off their MADBarcode argument.
@interface MADBarcodeElementSourceDouble : NSObject

@property (nonatomic, assign) BOOL has2dComponent;
@property (nonatomic, assign) BOOL has2dComponentEnabled;
@property (nonatomic, assign) int16_t barcodeType;
@property (nonatomic, assign) int16_t barcodeBorderStyle;
@property (nonatomic, assign) int16_t barcodeBorderWidth;
@property (nonatomic, assign) int16_t barcodeHeight;
@property (nonatomic, assign) BOOL humanReadable;
@property (nonatomic, assign) int16_t option1;
@property (nonatomic, assign) int16_t option2;
@property (nonatomic, assign) int16_t option3;
@property (nonatomic, assign) BOOL showErrorMessage;
@property (nonatomic, assign) int16_t whitespaceWidth;
@property (nonatomic, assign) float scale;

@end

@implementation MADBarcodeElementSourceDouble
@end

@interface RptqDocumentElementBarcodeTests : XCTestCase
@end

@implementation RptqDocumentElementBarcodeTests

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

- (RptqQueryField *)queryFieldNamed:(NSString *)name
						   tableName:(NSString *)tableName
							 context:(RptqStoreContext *)context
							document:(RptqDocument *)document {

	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = MADDataTypeString;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	RptqDatabaseSchemaTable *schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																													name:tableName
																											andQueryable:YES];
	[document.defaultDatabase addHasTablesObject:schemaTable];
	schemaField.inTable = schemaTable;

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	database:document.defaultDatabase
													  forManagedObjectContext:context];

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	return queryField;
}

- (RptqDocumentElementBarcode *)barcodeWithSource:(MADBarcodeElementSourceDouble *)source
									  inContext:(RptqStoreContext *)context {
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	return (RptqDocumentElementBarcode *)[RptqDocumentElementBarcode barcodeWithMtBarcode:(MADBarcode *)source
																		   queryFieldOne:field
																		   queryFieldTwo:nil];
}

#pragma mark - The base type

- (void)testFactoryStoresTheSymbologyInBarcodeTypeAndKeepsTheBaseType {
	RptqStoreContext *context = [self inMemoryContext];
	MADBarcodeElementSourceDouble *source = [[MADBarcodeElementSourceDouble alloc] init];
	source.barcodeType = 8;

	RptqDocumentElementBarcode *element = [self barcodeWithSource:source inContext:context];

	XCTAssertNotNil(element);
	XCTAssertEqual(element.documentObjectType, MADPrintPageElementTypeBarcode);
	XCTAssertEqual(element.type, (int16_t)MADPrintPageElementTypeBarcode);
	XCTAssertEqual(element.barcodeType, (int16_t)8);
}

- (void)testUpdateStoresTheSymbologyInBarcodeTypeAndKeepsTheBaseType {
	RptqStoreContext *context = [self inMemoryContext];
	MADBarcodeElementSourceDouble *source = [[MADBarcodeElementSourceDouble alloc] init];
	source.barcodeType = 8;

	RptqDocumentElementBarcode *element = [self barcodeWithSource:source inContext:context];
	int64_t fieldID = element.referencesField1.identifier;

	source.barcodeType = 20;
	[element updateWithBarcode:(MADBarcode *)source field1ID:fieldID field2ID:0];

	XCTAssertEqual(element.documentObjectType, MADPrintPageElementTypeBarcode);
	XCTAssertEqual(element.type, (int16_t)MADPrintPageElementTypeBarcode);
	XCTAssertEqual(element.barcodeType, (int16_t)20);
}

#pragma mark - The colours

- (void)testFactoryWritesAndReadsTheElementColours {
	RptqStoreContext *context = [self inMemoryContext];
	MADBarcodeElementSourceDouble *source = [[MADBarcodeElementSourceDouble alloc] init];
	source.barcodeType = 8;

	RptqDocumentElementBarcode *element = [self barcodeWithSource:source inContext:context];

	MADElementColor *background = element.backgroundColor;
	XCTAssertNotNil(background);
	CGFloat backgroundRed = 0.0, backgroundGreen = 0.0, backgroundBlue = 0.0, backgroundAlpha = 0.0;
#if TARGET_OS_OSX
	NSColor *srgbBg = [background colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
	XCTAssertNotNil(srgbBg);
	[srgbBg getRed:&backgroundRed green:&backgroundGreen blue:&backgroundBlue alpha:&backgroundAlpha];
	BOOL hasBackgroundComponents = (srgbBg != nil);
#else
	BOOL hasBackgroundComponents = [background getRed:&backgroundRed
												green:&backgroundGreen
												 blue:&backgroundBlue
												alpha:&backgroundAlpha];
#endif
	XCTAssertTrue(hasBackgroundComponents);
	XCTAssertEqualWithAccuracy(backgroundRed, 1.0, 0.0001);
	XCTAssertEqualWithAccuracy(backgroundGreen, 1.0, 0.0001);
	XCTAssertEqualWithAccuracy(backgroundBlue, 1.0, 0.0001);
	XCTAssertEqualWithAccuracy(backgroundAlpha, 1.0, 0.0001);

	MADElementColor *foreground = element.foregroundColor;
	XCTAssertNotNil(foreground);
	CGFloat foregroundRed = 1.0, foregroundGreen = 1.0, foregroundBlue = 1.0, foregroundAlpha = 0.0;
#if TARGET_OS_OSX
	NSColor *srgbFg = [foreground colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
	XCTAssertNotNil(srgbFg);
	[srgbFg getRed:&foregroundRed green:&foregroundGreen blue:&foregroundBlue alpha:&foregroundAlpha];
	BOOL hasForegroundComponents = (srgbFg != nil);
#else
	BOOL hasForegroundComponents = [foreground getRed:&foregroundRed
												green:&foregroundGreen
												 blue:&foregroundBlue
												alpha:&foregroundAlpha];
#endif
	XCTAssertTrue(hasForegroundComponents);
	XCTAssertEqualWithAccuracy(foregroundRed, 0.0, 0.0001);
	XCTAssertEqualWithAccuracy(foregroundGreen, 0.0, 0.0001);
	XCTAssertEqualWithAccuracy(foregroundBlue, 0.0, 0.0001);
	XCTAssertEqualWithAccuracy(foregroundAlpha, 1.0, 0.0001);

	// The write landed in the four component columns the schema declares.
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"backgroundColorR"] doubleValue], 1.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"backgroundColorG"] doubleValue], 1.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"backgroundColorB"] doubleValue], 1.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"backgroundColorA"] doubleValue], 1.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"foregroundColorR"] doubleValue], 0.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"foregroundColorG"] doubleValue], 0.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"foregroundColorB"] doubleValue], 0.0, 0.0001);
	XCTAssertEqualWithAccuracy([[element.backingObject attributeValue:@"foregroundColorA"] doubleValue], 1.0, 0.0001);
}

@end
