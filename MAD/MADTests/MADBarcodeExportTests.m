//
//  MADBarcodeExportTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Export and accessibility coverage for a barcode line.  A store-backed document
//  holds one barcode element, created through the element factory with Code 39 and
//  two known inputs; the test builds the same MADReportLineRepresentation the page
//  walk builds and hands it to the exporters' own line serializers.  That pins the
//  whole path the render-side formats take: the kind token (the element type with
//  "MADPrintPageElementType" stripped) and the value (the line's resolved -text).
//
//  The barcode element is Apple-only -- MADBarcodes is not in the Linux build -- so
//  this suite is not part of the Linux test set.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADAccessibilityLine.h"
#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "MADDocumentObjectType.h"
#import "MADMock.h"
#import "MADPrintPageElement.h"
#import "MADPrintPageElement+Constructor.h"
#import "MADPrintPageElementBarcode.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADReportExporterHTML.h"
#import "MADReportExporterHTMLFlow.h"
#import "MADReportExporterJSONReport.h"
#import "MADReportLineRepresentation.h"
#import "MADStore.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqStoreContext.h"

// The element's two inputs, and what the exports must spell.  The characters are
// chosen to prove the HTML and JSON escaping: & < > " ' all appear.
static NSString * const MADBarcodeExportInput1 = @"A&B<C>D\"E'F";
static NSString * const MADBarcodeExportInput2 = @"<2>";
static NSString * const MADBarcodeExportText = @"A&B<C>D\"E'F<2>";
static NSString * const MADBarcodeExportEscapedText = @"A&amp;B&lt;C&gt;D&quot;E&#39;F&lt;2&gt;";

@class MADBarcode;

// The properties the two barcode paths read off their MADBarcode argument.
@interface MADBarcodeExportBarcodeDouble : NSObject

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

@implementation MADBarcodeExportBarcodeDouble
@end

// Everything MADPrintPageRendererDataSourceProtocol requires; the barcode element
// reads -database (for the field keys) and -dataForRow:error: (for the values).
@interface MADBarcodeExportDataSourceDouble : NSObject <MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@property (nonatomic, copy) NSDictionary *rowData;

@end

@implementation MADBarcodeExportDataSourceDouble

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID { return @[]; }
- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber { return @[]; }
- (NSArray <NSString *> *)groupLevelKeyNames { return @[]; }

- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID
													error:(NSError * __autoreleasing *)error {
	if (error != NULL) *error = nil;
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

// The pieces of the walk the exporters read: the element, its drawing object and the
// line representation built over them.
@interface MADBarcodeExportFixture : NSObject

@property (nonatomic, strong) RptqDocumentElementBarcode *element;
@property (nonatomic, strong) MADPrintPageElementBarcode *drawingObject;
@property (nonatomic, strong) MADReportLineRepresentation *line;

@end

@implementation MADBarcodeExportFixture
@end

// The serializers are implementation details of the formats; these test-only
// categories are the deliberate bridge, the way the renderer tests bridge theirs.
@interface MADReportExporterJSONReport (MADBarcodeExportTesting)
- (void)appendLineToJSON:(NSMutableString *)json line:(MADReportLineRepresentation *)line;
@end

@interface MADReportExporterHTML (MADBarcodeExportTesting)
- (void)appendLine:(MADReportLineRepresentation *)line toHTML:(NSMutableString *)html;
@end

@interface MADReportExporterHTMLFlow (MADBarcodeExportTesting)
- (void)appendLine:(MADReportLineRepresentation *)line toHTML:(NSMutableString *)html;
@end

@interface MADBarcodeExportTests : XCTestCase
@end

@implementation MADBarcodeExportTests

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

/// A document whose detail section holds one barcode element, and the line the page
/// walk would build for it.  Code 39 (zint's type 8) is a symbology the factory
/// supports, so a real MADBarcode is built; the values come from the row the
/// reference asks its datasource for.
- (MADBarcodeExportFixture *)fixture {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field1 = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	RptqQueryField *field2 = [self queryFieldNamed:@"Code" tableName:@"Invoice" context:context document:document];

	MADBarcodeExportBarcodeDouble *source = [[MADBarcodeExportBarcodeDouble alloc] init];
	source.barcodeType = 8;	// Code 39

	RptqDocumentElementBarcode *element;
	element = (RptqDocumentElementBarcode *)[RptqDocumentElementBarcode barcodeWithMtBarcode:(MADBarcode *)source
																			   queryFieldOne:field1
																			   queryFieldTwo:field2];
	XCTAssertNotNil(element);

	RptqDocumentSection *detail;
	detail = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeBody
									  forManagedObjectContext:context];
	document.hasDetailSection = detail;

	RptqDocumentSectionRows *row;
	row = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:context];
	detail.hasRows = [NSOrderedSet orderedSetWithObject:row];

	[detail addDocumentObject:element withDropPoint:CGPointMake(10.0, 20.0) managedObjectContext:context];

	MADBarcodeExportDataSourceDouble *datasource = [[MADBarcodeExportDataSourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];
	datasource.rowData = @{ @"Invoice0.Name" : MADBarcodeExportInput1,
							@"Invoice0.Code" : MADBarcodeExportInput2 };

	MADDocumentObjectDataReference *definition;
	definition = [MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																	  delegate:nil
																		  page:0
																		  item:element
																		itemID:7];

	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:definition];

	MADBarcodeExportFixture *fixture = [[MADBarcodeExportFixture alloc] init];
	fixture.element = element;
	fixture.drawingObject = (MADPrintPageElementBarcode *)drawingObject;
	fixture.line = [[MADReportLineRepresentation alloc] initWithObject:drawingObject
																 type:element.documentObjectType
																frame:CGRectMake(10.0, 20.0, 80.0, 30.0)];
	return fixture;
}

#pragma mark - The line the walk builds

- (void)testTheWalkBuildsABarcodeLineWithTheResolvedText {
	MADBarcodeExportFixture *fixture = [self fixture];

	XCTAssertEqualObjects(NSStringFromClass([fixture.drawingObject class]), @"MADPrintPageElementBarcode");
	XCTAssertEqual(fixture.element.documentObjectType, MADPrintPageElementTypeBarcode);
	XCTAssertEqual(fixture.element.barcodeType, (int16_t)8);
	XCTAssertEqual(fixture.line.elementType, MADPrintPageElementTypeBarcode);
	XCTAssertEqualObjects(fixture.line.text, MADBarcodeExportText);
}

#pragma mark - json-report

- (void)testJSONReportSerializesTheBarcodeLine {
	MADBarcodeExportFixture *fixture = [self fixture];
	NSMutableString *json = [[NSMutableString alloc] init];
	MADReportExporterJSONReport *exporter = [[MADReportExporterJSONReport alloc] init];

	[exporter appendLineToJSON:json line:fixture.line];

	NSString *expected = @"{\"kind\": \"Barcode\", \"frame\": [10, 20, 80, 30], \"text\": \"A&B<C>D\\\"E'F<2>\"}";
	XCTAssertEqualObjects(json, expected);
}

#pragma mark - html

- (void)testHTMLFacsimileSerializesTheBarcodeLine {
	MADBarcodeExportFixture *fixture = [self fixture];
	NSMutableString *html = [[NSMutableString alloc] init];
	MADReportExporterHTML *exporter = [[MADReportExporterHTML alloc] init];

	[exporter appendLine:fixture.line toHTML:html];

	NSString *expected = @"<div class=\"line\" data-kind=\"Barcode\" style=\"left:10pt; top:20pt; width:80pt; height:30pt\">"
						  "A&amp;B&lt;C&gt;D&quot;E&#39;F&lt;2&gt;</div>\n";
	XCTAssertEqualObjects(html, expected);
}

#pragma mark - html-flow

- (void)testHTMLFlowSerializesTheBarcodeLine {
	MADBarcodeExportFixture *fixture = [self fixture];
	NSMutableString *html = [[NSMutableString alloc] init];
	MADReportExporterHTMLFlow *exporter = [[MADReportExporterHTMLFlow alloc] init];

	[exporter appendLine:fixture.line toHTML:html];

	NSString *expected = @"<td class=\"s0\" data-kind=\"Barcode\">A&amp;B&lt;C&gt;D&quot;E&#39;F&lt;2&gt;</td>";
	XCTAssertEqualObjects(html, expected);
}

#pragma mark - Accessibility

- (void)testAccessibilityLineCarriesTheBarcodeText {
	MADBarcodeExportFixture *fixture = [self fixture];

	MADAccessibilityLine *line = [[MADAccessibilityLine alloc] initWithValue:fixture.drawingObject
																		type:fixture.element.documentObjectType
																	andFrame:fixture.line.frame];

	XCTAssertEqualObjects(line.label, MADBarcodeExportText);
}

@end
