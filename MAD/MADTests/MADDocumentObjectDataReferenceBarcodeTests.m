//
//  MADDocumentObjectDataReferenceBarcodeTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReferenceBarcode: the handle over a
//  barcode element.  It hands the element itself back as the MADBarcodeProtocol object and
//  builds each of the two field keys from its referenced query field's table alias and
//  schema field name.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADMock.h"
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
#import "RptqDocumentElement+Extras.h"

// The smallest datasource the reference actually asks questions of: `database` only.
@interface MADDataReferenceBarcodeDatasourceDouble : NSObject <MADPrintPageRendererDataSourceProtocol>
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@end

@implementation MADDataReferenceBarcodeDatasourceDouble

- (NSArray<MADResult *> *)groupLevelKeys:(__unused int64_t)rowID { return @[]; }
- (NSArray<MADResult *> *)groupKeys:(__unused int64_t)rowID groupNumber:(__unused int64_t)groupNumber { return @[]; }
- (NSArray<NSString *> *)groupLevelKeyNames { return @[]; }

- (NSDictionary<NSString *, MADResult *> *)dataForRow:(__unused NSUInteger)rowID
												error:(__unused NSError * __autoreleasing *)error { return nil; }
- (NSDictionary *)dataForRowReportFirst { return nil; }
- (NSDictionary *)dataForRowReportLast { return nil; }
- (NSDictionary *)dataForRowPageFirst:(__unused NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRowPageLast:(__unused NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRow:(__unused NSUInteger)rowID
					  column:(__unused NSString *)columnKey
					   error:(__unused NSError * __autoreleasing *)error { return nil; }
- (NSArray<__kindof NSDictionary *> *)dataForGroups:(__unused NSArray *)groupKeys
											groupID:(__unused int64_t)groupID { return @[]; }
- (__kindof NSObject<NSCopying> *)dataForRows:(__unused NSArray *)rowIDs
									   column:(__unused NSString *)columnKey
									   groups:(__unused NSArray *)groupKeys
									 function:(__unused MTAggregateFunctionType)function
									  groupBy:(__unused MTAggregateGroupByType)groupBy { return nil; }
- (NSUInteger)rowIDFirstOfReport { return 0; }
- (NSUInteger)rowIDLastOfReport { return 0; }
- (NSUInteger)rowIDFirstOfPage:(__unused NSUInteger)page { return 0; }
- (NSUInteger)rowIDLastOfPage:(__unused NSUInteger)page { return 0; }
- (NSArray<NSNumber *> *)rowIDsForPage:(__unused NSUInteger)pageIndex { return @[]; }

- (void)updatePrintingReportFormatter { }

@end

@interface MADDocumentObjectDataReferenceBarcodeTests : XCTestCase
@end

@implementation MADDocumentObjectDataReferenceBarcodeTests

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

- (RptqDocumentElementBarcode *)barcodeElementInContext:(RptqStoreContext *)context
												 field1:(RptqQueryField *)field1
												 field2:(RptqQueryField *)field2 {
	RptqDocumentElementBarcode *element = (RptqDocumentElementBarcode *)[context insertObjectForEntity:@"RptqDocumentElementBarcode" identifier:0];
	element.type = MADPrintPageElementTypeBarcode;
	element.referencesField1 = field1;
	element.referencesField2 = field2;
	return element;
}

- (MADDocumentObjectDataReferenceBarcode *)referenceForElement:(RptqDocumentElementBarcode *)element
													 datasource:(id <MADPrintPageRendererDataSourceProtocol>)datasource {
	return (MADDocumentObjectDataReferenceBarcode *)[MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																											 delegate:nil
																												 page:4
																												 item:element
																											   itemID:21];
}

#pragma mark - Tests

- (void)testFactoryReturnsBarcodeReference {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementBarcode *element = [self barcodeElementInContext:context field1:nil field2:nil];

	MADDocumentObjectDataReferenceBarcode *reference = [self referenceForElement:element datasource:nil];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceBarcode");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeBarcode);
}

- (void)testBarcodeIsTheElementItself {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementBarcode *element = [self barcodeElementInContext:context field1:nil field2:nil];

	MADDocumentObjectDataReferenceBarcode *reference = [self referenceForElement:element datasource:nil];

	XCTAssertEqual(reference.barcode, element);
}

- (void)testEachFieldKeyQualifiesItsFieldWithItsTableAlias {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field1 = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	RptqQueryField *field2 = [self queryFieldNamed:@"Code" tableName:@"Customer" context:context document:document];
	RptqDocumentElementBarcode *element = [self barcodeElementInContext:context field1:field1 field2:field2];
	MADDataReferenceBarcodeDatasourceDouble *datasource = [[MADDataReferenceBarcodeDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceBarcode *reference = [self referenceForElement:element datasource:datasource];

	XCTAssertEqualObjects(reference.fieldKey1, @"Invoice0.Name");
	XCTAssertEqualObjects(reference.fieldKey2, @"Customer0.Code");
}

- (void)testFieldKeysAreNilWithoutADatasource {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field1 = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	RptqDocumentElementBarcode *element = [self barcodeElementInContext:context field1:field1 field2:nil];

	MADDocumentObjectDataReferenceBarcode *reference = [self referenceForElement:element datasource:nil];

	XCTAssertNil(reference.fieldKey1);
	XCTAssertNil(reference.fieldKey2);
}

- (void)testFormattedStringsUseEachFieldType {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field1 = [self queryFieldNamed:@"Name" tableName:@"Invoice" context:context document:document];
	RptqQueryField *field2 = [self queryFieldNamed:@"Code" tableName:@"Customer" context:context document:document];
	RptqDocumentElementBarcode *element = [self barcodeElementInContext:context field1:field1 field2:field2];
	MADDocumentObjectDataReferenceBarcode *reference = [self referenceForElement:element datasource:nil];

	NSString *formatted1 = [reference formattedStringForValue1:@"abc"];
	NSString *formatted2 = [reference formattedStringForValue2:@"abc"];
	XCTAssertEqualObjects(formatted1, @"abc");
	XCTAssertEqualObjects(formatted2, @"abc");
}

@end
