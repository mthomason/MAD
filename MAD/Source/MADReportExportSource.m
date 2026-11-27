//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExportSource.m
//  MAD
//
//  See MADReportExportSource.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExportSource.h"

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADQueryFull.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>

#import <MADSqlite3/MADDataTableFast.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSError.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

#import <math.h>
#import <stdlib.h>
#import <string.h>
#import <time.h>

// "MADDataTypeString" is the runtime's stable spelling, but the prefix is noise in a
// contract; the tail is the name a consumer reads.  Not +dataTypeDisplay:, which is
// localized and so would make the JSON depend on the device's language.
static NSString *MADReportExportTypeName(MADDataType type) {
	NSString *name = NSStringFromMADDataType(type);
	static NSString * const prefix = @"MADDataType";
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

@interface MADReportExportSource ()

+ (NSString *)driverNameForDocument:(id <MADDocumentDataProtocol>)document;

@property (nonatomic, readwrite, strong) id <MADDocumentDataProtocol> document;
@property (nonatomic, readwrite, strong, nullable) MADDataResult *result;
@property (nonatomic, readwrite, copy) NSString *driverName;
@property (nonatomic, readwrite, copy) NSString *sql;
@property (nonatomic, readwrite, copy) NSArray <NSString *> *columnKeys;
@property (nonatomic, readwrite, copy) NSDictionary <NSString *, RptqDatabaseSchemaField *> *schemaFields;

@end

@implementation MADReportExportSource

+ (instancetype)sourceWithDocument:(id <MADDocumentDataProtocol>)document error:(NSError * _Nullable __autoreleasing *)error {

	if (document == nil) {
		if (error) {
			*error = [NSError errorWithDomain: @"MADReportExport"
										 code: 1
									 userInfo: @{ NSLocalizedDescriptionKey: NSLocalizedString(@"There is no document to export.", @"Error when an export has no document.") }];
		}
		return nil;
	}

	// A composed document has no single compilable query; its committed root result
	// and its persisted output projection are the schema, fields and rows.
	if (document.activeDocumentModel.rootQuery != nil) {
		return [self composedSourceWithDocument: document error: error];
	}

	// The SQL build is what populates the query's fieldKeys and fields, so the column
	// descriptions below are read after it, not before.
	NSError *sqlError = nil;
	NSString *sql = [document.mainQuery copySQLWithManagedObjectContext: document.storeContext error: &sqlError];
	if (sql.length == 0) {
		if (error) {
			*error = sqlError ?: [NSError errorWithDomain: @"MADReportExport"
													 code: 2
												 userInfo: @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The document's query generated no SQL.", @"Error when the document query produced no SQL to export.") }];
		}
		return nil;
	}

	MADReportExportSource *source = [[MADReportExportSource alloc] init];
	source.document = document;
	// Pin the published generation now: a refresh that publishes while an exporter
	// is running must not change the rows or the column map under it.
	source.result = document.currentResult;
	source.sql = sql;
	source.driverName = [MADReportExportSource driverNameForDocument: document];

	// The row table's columns are what the rows are keyed by -- and it keys them by
	// the column's *identifier*, which is the field key the SELECT list writes
	// ("Customer0.City"), while the table's own columnKeys are the c<hash> names of
	// its storage (MADDataTableFast -addColumn:, -newCurrentObject:).  The field keys
	// are what a consumer reads, so those are what an export is keyed by.
	//
	// A result with no rows has no columns in the table at all -- the sqlite driver
	// builds them from the first row -- so the query's own field keys stand in, and
	// the export still describes the shape of something empty rather than nothing
	// (docs/developers/data-object.md section 3.6).
	MADDataTableFast *table = source.result.dataTable ?: document.dataTable;
	NSMutableArray <NSString *> *columnKeys = [NSMutableArray arrayWithCapacity: table.columnKeys.count];
	for (NSString *tableColumnKey in table.columnKeys) {
		MADDataColumn *column = table.columns[tableColumnKey];
		[columnKeys addObject: column.identifier ?: tableColumnKey];
	}
	if (columnKeys.count == 0) {
		for (NSString *fieldKey in document.mainQuery.fieldKeys) {
			[columnKeys addObject: fieldKey];
		}
	}
	source.columnKeys = columnKeys;

	NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields =
		[NSMutableDictionary dictionaryWithCapacity: source.columnKeys.count];
	for (NSString *columnKey in source.columnKeys) {
		id field = document.mainQuery.fields[columnKey];
		if ([field isKindOfClass: [RptqDatabaseSchemaField class]]) {
			fields[columnKey] = field;
		}
	}
	source.schemaFields = fields;

	return source;
}

+ (NSError *)errorForUnrefreshedNode:(RptqQuery *)query {
	return [NSError errorWithDomain:@"MADReportExport" code:3 userInfo:@{
		NSLocalizedDescriptionKey: [NSString stringWithFormat:
			NSLocalizedString(@"The node '%@' has not been refreshed; refresh the document first.", @"Export of an unrefreshed node."),
			query.name.length > 0 ? query.name : @"?"] }];
}

+ (nullable instancetype)sourceWithDocument:(id <MADDocumentDataProtocol>)document
									  query:(nullable RptqQuery *)query
									  error:(NSError * _Nullable __autoreleasing *)error {
	// The report's layout/result root, or no explicit node, reads the document the way
	// it always has.  An ordinary report has no composed root, so its single/default
	// query is the root here too -- otherwise a no-`query` read would look for a node
	// result that an ordinary refresh never publishes.
	if (query == nil || [query isLayoutRootInDocument: document.activeDocumentModel]) {
		return [self sourceWithDocument:document error:error];
	}

	MADDataResult *result = document.nodeResults[@(query.identifier)];
	if (result == nil) {
		if (error != NULL) *error = [self errorForUnrefreshedNode: query];
		return nil;
	}

	MADReportExportSource *source = [[MADReportExportSource alloc] init];
	source.document = document;
	source.result = result;
	source.sql = @"<node>";

	// The node's committed columns, keyed by their logical identifier (the same
	// physical → logical mapping the root source does): the c<hash> table keys are
	// storage, the column.identifier is the field key the SELECT list wrote.
	MADDataTableFast *table = result.dataTable;
	NSMutableArray <NSString *> *columnKeys = [NSMutableArray arrayWithCapacity: table.columnKeys.count];
	for (NSString *tableColumnKey in table.columnKeys) {
		MADDataColumn *column = table.columns[tableColumnKey];
		[columnKeys addObject: column.identifier ?: tableColumnKey];
	}
	NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields = [NSMutableDictionary dictionary];

	if ([query isComposing]) {
		source.driverName = @"composed";
		NSArray <RptqQueryField *> *outputs = [query orderedOutputFieldsWithError:NULL] ?: @[];
		for (RptqQueryField *output in outputs) {
			if (output.outputKey != nil) fields[output.outputKey] = output.databaseSchemaField;
		}
		if (columnKeys.count == 0) {
			for (RptqQueryField *output in outputs) {
				if (output.outputKey != nil) [columnKeys addObject:output.outputKey];
			}
		}
	} else {
		RptqDatabase *database = query.inDatabase;
		source.driverName = database.databaseDriverType ?: @"";
		for (RptqQueryTable *table in query.hasQueryTables) {
			NSString *alias = table.alias.length > 0 ? table.alias : (table.databaseSchemaTable.name ?: @"");
			for (RptqQueryField *field in table.hasQueryFields) {
				NSString *name = field.databaseSchemaField.name ?: @"";
				if (name.length == 0) continue;
				NSString *key = alias.length > 0 ? [NSString stringWithFormat:@"%@.%@", alias, name] : name;
				fields[key] = field.databaseSchemaField;
			}
		}
	}

	source.columnKeys = columnKeys;
	source.schemaFields = fields;
	return source;
}

/// The export source for a composed document: the committed root's columns and
/// rows, and the persisted output projection's schema fields.  The root result's
/// columns are keyed by the output keys the composer wrote, which is the order the
/// document persists.
+ (instancetype)composedSourceWithDocument:(id <MADDocumentDataProtocol>)document
									 error:(NSError * _Nullable __autoreleasing *)error {

	RptqDocument *model = document.activeDocumentModel;
	NSArray <RptqQueryField *> *outputs = [model orderedCompositionOutputsWithError: error];
	if (outputs == nil) return nil;

	MADReportExportSource *source = [[MADReportExportSource alloc] init];
	source.document = document;
	source.result = document.currentResult;
	source.driverName = @"composed";
	// The root has no single SQL statement the way an ordinary query does; a reader
	// dispatches on the document's composition, not on this description.
	source.sql = @"<composed root>";

	MADDataTableFast *table = source.result.dataTable ?: document.dataTable;
	NSMutableArray <NSString *> *columnKeys = [NSMutableArray arrayWithCapacity: table.columnKeys.count];
	for (NSString *tableColumnKey in table.columnKeys) {
		MADDataColumn *column = table.columns[tableColumnKey];
		[columnKeys addObject: column.identifier ?: tableColumnKey];
	}
	// A root with no published result still describes its projection from the
	// persisted outputs, so an empty composed export is shaped, not absent.
	if (columnKeys.count == 0) {
		for (RptqQueryField *output in outputs) {
			[columnKeys addObject: output.outputKey];
		}
	}
	source.columnKeys = columnKeys;

	NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields =
		[NSMutableDictionary dictionaryWithCapacity: outputs.count];
	for (RptqQueryField *output in outputs) {
		fields[output.outputKey] = output.databaseSchemaField;
	}
	source.schemaFields = fields;

	return source;
}

+ (NSString *)driverNameForDocument:(id <MADDocumentDataProtocol>)document {
	for (RptqDatabase *schema in document.activeDocumentModel.hasDatabaseSchemas) {
		if (schema.databaseDriverType.length > 0) {
			return schema.databaseDriverType;
		}
	}
	return @"";
}

#pragma mark - Columns

- (RptqDatabaseSchemaField *)fieldForColumn:(NSString *)columnKey {
	return self.schemaFields[columnKey];
}

- (NSString *)columnName:(NSString *)columnKey {
	NSString *name = [self fieldForColumn: columnKey].name;
	return name.length > 0 ? name : columnKey;
}

- (NSString *)columnTable:(NSString *)columnKey {
	NSString *table = [self fieldForColumn: columnKey].inTable.name;
	return table.length > 0 ? table : nil;
}

- (NSString *)columnType:(NSString *)columnKey {
	RptqDatabaseSchemaField *field = [self fieldForColumn: columnKey];
	if (field != nil) {
		return MADReportExportTypeName(field.dataType);
	}
	// The stored column, when the document does not name the schema field: the table
	// keys its columns by the c<hash> name, so the field key is looked up first.
	MADDataTableFast *table = self.result.dataTable ?: self.document.dataTable;
	NSString *tableColumnKey = [table columnKeyForColumnName: columnKey];
	MADDataColumn *column = tableColumnKey != nil ? table.columns[tableColumnKey] : nil;
	return column != nil ? MADReportExportTypeName(column.type) : nil;
}

#pragma mark - Rows

- (NSUInteger)numberOfRows {
	if (self.result != nil) return self.result.numberOfRows;
	return self.document.numberOfResults;
}

- (NSEnumerator <NSDictionary <NSString *, id> *> *)rowEnumerator {
	MADDataTableFast *table = self.result.dataTable ?: self.document.dataTable;
	return [table objectEnumerator];
}

#pragma mark - Values

- (NSString *)stringForValue:(id)value {
	if (value == nil || value == [NSNull null]) return @"";
	if ([value isKindOfClass: [NSString class]]) return value;
	if ([value isKindOfClass: [NSNumber class]]) return [MADReportExportSource stringForNumber: (NSNumber *)value];
	if ([value isKindOfClass: [NSDate class]]) return [MADReportExportSource stringForDate: value];
	if ([value isKindOfClass: [NSData class]]) return [value base64EncodedStringWithOptions: 0];
	return [value description];
}

+ (NSString *)stringForNumber:(NSNumber *)number {
	const char *type = number.objCType;
	if (type != NULL && (*type == 'd' || *type == 'f')) {
		double value = number.doubleValue;
		if (value == floor(value) && fabs(value) < 1e15) {
			// An integral real prints without a fraction, so a JSON reader sees 3 where
			// the value is exactly 3 rather than 3.0000000000000004.
			return [[NSString alloc] initWithFormat: @"%.0f", value];
		}
		// 15 significant digits round-trip most doubles and read well; when they do
		// not, 17 do.  printf, not NSNumber -description: the C locale is the same on
		// both platforms, and no locale can move the decimal point.
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "%.15g", value);
		if (strtod(buffer, NULL) != value) {
			snprintf(buffer, sizeof(buffer), "%.17g", value);
		}
		NSString *spelled = [NSString stringWithUTF8String: buffer];
		return spelled ?: @"";
	}
	return [[NSString alloc] initWithFormat: @"%lld", number.longLongValue];
}

+ (NSString *)stringForDate:(NSDate *)date {
	// Computed from the epoch rather than through NSDateFormatter: the locale must not
	// reach a contract's bytes, and gmtime_r is the same everywhere.
	time_t seconds = (time_t)date.timeIntervalSince1970;
	struct tm parts;
	gmtime_r(&seconds, &parts);
	return [[NSString alloc] initWithFormat: @"%04d-%02d-%02dT%02d:%02d:%02dZ",
			parts.tm_year + 1900, parts.tm_mon + 1, parts.tm_mday,
			parts.tm_hour, parts.tm_min, parts.tm_sec];
}

@end
