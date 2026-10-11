//
//  MADDocumentObjectDataReferenceLabelDynamicTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceLabelDynamicTests.m:
//  MADDocumentObjectDataReferenceLabelDynamic, the handle over a data label.
//  Its fieldKey is the qualified name built from the referenced query field's
//  table alias and schema field name via the datasource's database;
//  formattedStringForValue: reads the value using the schema field's data type.
//
//  The datasource is consulted through its `database` property only, so the
//  double below returns a MADMock database (queryKey:table: -> "<table>.<field>")
//  and empty answers for everything else; the mock is the portable half of
//  MADMock (Tests/Support/MADMock.h).  The store is a real SQLite file under a
//  per-test temp directory, as in the Xcode suite.
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>

#import "MADMock.h"
#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElement+Extras.h>

// The smallest datasource the reference actually asks questions of: `database` only.
@interface MADDataReferenceLabelDynamicDatasourceDouble : NSObject <MADPrintPageRendererDataSourceProtocol>
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;
@end

@implementation MADDataReferenceLabelDynamicDatasourceDouble

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

// A query field wired the way the document model expects: schema field -> schema
// table -> query table -> query field.
static RptqQueryField *queryFieldNamed(NSString *name, NSString *tableName,
									   RptqStoreContext *context, RptqDocument *document) {
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

static MADDocumentObjectDataReferenceLabelDynamic *referenceForField(RptqQueryField *field,
																	 RptqStoreContext *context,
																	 id <MADPrintPageRendererDataSourceProtocol> datasource) {
	RptqDocumentElementLabelDataField *element = (RptqDocumentElementLabelDataField *)[context insertObjectForEntity:@"RptqDocumentElementLabelDataField" identifier:0];
	element.type = MADPrintPageElementTypeLabelDynamic;
	element.referencesQueryField = field;
	return (MADDocumentObjectDataReferenceLabelDynamic *)[MADDocumentObjectDataReference newDocumentObjectDataReference:datasource
																												delegate:nil
																													page:1
																													item:element
																												  itemID:7];
}

#pragma mark - Tests

static void testFactoryReturnsLabelDynamicReference(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Name", @"Invoice", context, document);

	MADDocumentObjectDataReferenceLabelDynamic *reference = referenceForField(field, context, nil);

	MAD_PASS_EQUAL(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceLabelDynamic",
				   "the factory returns the dynamic-label reference");
	MAD_PASS(reference.type == MADPrintPageElementTypeLabelDynamic, "the reference reads the element's type");
}

static void testFieldKeyQualifiesTheFieldWithTheTableAlias(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Name", @"Invoice", context, document);
	MADDataReferenceLabelDynamicDatasourceDouble *datasource = [[MADDataReferenceLabelDynamicDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];

	MADDocumentObjectDataReferenceLabelDynamic *reference = referenceForField(field, context, datasource);

	// The first table keeps dropIndex 0, so the alias is the table name plus "0".
	MAD_PASS_EQUAL(reference.fieldKey, @"Invoice0.Name", "the field key qualifies the field with the table alias");
}

static void testFieldKeyIsNilWithoutADatasource(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Name", @"Invoice", context, document);

	MADDocumentObjectDataReferenceLabelDynamic *reference = referenceForField(field, context, nil);

	MAD_PASS(reference.fieldKey == nil, "without a datasource there is no field key");
}

static void testFormattedStringUsesTheSchemaFieldType(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqQueryField *field = queryFieldNamed(@"Name", @"Invoice", context, document);
	MADDataReferenceLabelDynamicDatasourceDouble *datasource = [[MADDataReferenceLabelDynamicDatasourceDouble alloc] init];
	datasource.database = [MADMock mockDatabase];
	MADDocumentObjectDataReferenceLabelDynamic *reference = referenceForField(field, context, datasource);

	NSString *formatted = [reference formattedStringForValue:@"abc"];
	MAD_PASS_EQUAL(formatted, @"abc", "the string formats through the schema field type");
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceLabelDynamicTests",
	MAD_TEST(testFactoryReturnsLabelDynamicReference),
	MAD_TEST(testFieldKeyQualifiesTheFieldWithTheTableAlias),
	MAD_TEST(testFieldKeyIsNilWithoutADatasource),
	MAD_TEST(testFormattedStringUsesTheSchemaFieldType));
