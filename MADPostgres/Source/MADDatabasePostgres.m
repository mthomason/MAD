//
//  MADDatabasePostgres.m
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabasePostgres.h"
#import "MADDatabaseConnectionPostgres.h"
#import "MADPostgresConnection.h"
#import "MADDataTypePostgres.h"

#import <MADFoundation/madlog.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADCredential.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <MADPostgres/libpq-fe.h>
#import <MADPostgres/pg_type_d.h>

#import <stdlib.h>
#import <string.h>

@interface MADDatabasePostgres ()

@property (nonatomic, strong) MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection;
@property (nonatomic, strong, nullable) MADPostgresConnection *liveConnection;

@end

static NSString *MADQuotePostgresComponent(NSString *component) {
	NSString *escaped = [component stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
	return [[NSString alloc] initWithFormat:@"\"%@\"", escaped];
}

static void MADSplitPostgresTableName(NSString *tableName,
									  NSString * __autoreleasing *outSchema,
									  NSString * __autoreleasing *outBareTable) {
	NSRange dotRange = [tableName rangeOfString:@"."];
	if (dotRange.location != NSNotFound && dotRange.location > 0 && dotRange.location + 1 < tableName.length) {
		*outSchema = [tableName substringToIndex:dotRange.location];
		*outBareTable = [tableName substringFromIndex:dotRange.location + 1];
	} else {
		*outSchema = @"public";
		*outBareTable = tableName ?: @"";
	}
}

static int MADHexNibble(char c) {
	if (c >= '0' && c <= '9') return c - '0';
	if (c >= 'a' && c <= 'f') return c - 'a' + 10;
	if (c >= 'A' && c <= 'F') return c - 'A' + 10;
	return -1;
}

@implementation MADDatabasePostgres

@dynamic databaseConnection;

#pragma mark - Driver identity and SQL quoting

+ (NSString *)imageIconName { return @"UIImageExportTypePostgres"; }
+ (NSString *)driverName { return @"PostgreSQL"; }

+ (NSString *)identifierQuoteCharacters { return @"\"\""; }

+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
	if (fieldOrTableName == nil || fieldOrTableName.length == 0) {
		return @"";
	}
	if ([fieldOrTableName rangeOfString:@"."].location == NSNotFound) {
		return MADQuotePostgresComponent(fieldOrTableName);
	}
	NSArray<NSString *> *parts = [fieldOrTableName componentsSeparatedByString:@"."];
	NSMutableArray<NSString *> *quotedParts = [[NSMutableArray alloc] initWithCapacity:parts.count];
	for (NSString *part in parts) {
		if (part.length > 0) {
			[quotedParts addObject:MADQuotePostgresComponent(part)];
		}
	}
	return [quotedParts componentsJoinedByString:@"."];
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
	return [MADDatabasePostgres newSafeIdentifier:fieldOrTableName];
}

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
	NSString *safeTable = [self newSafeIdentifier:tableName];
	NSString *safeField = [self newSafeIdentifier:fieldName];
	if (safeTable.length == 0) return safeField;
	return [[NSString alloc] initWithFormat:@"%@.%@", safeTable, safeField];
}

- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [MADDatabasePostgres newSafeQueryField:fieldName andTable:tableName];
}

- (NSString *)fieldAliasForField:(NSString *)field withSafeTableName:(NSString *)safeTableName {
	return [[safeTableName stringByAppendingString:@"."] stringByAppendingString:[self newSafeIdentifier:field]];
}

- (NSString *)newSafeLiteral:(NSString *)value {
	if (value == nil) return @"NULL";
	MADPostgresConnection *connection = self.liveConnection;
	if (connection != nil && connection.isConnected) {
		NSString *escaped = [connection escapeLiteral:value];
		if (escaped != nil) {
			return escaped;
		}
		os_log_error(GetPostgresLog(), "MADDatabasePostgres: session failed to escape literal; falling back to ANSI quoting.");
	}
	return [super newSafeLiteral:value];
}

+ (NSError *)errorCouldNotGetCredientals {
	return [NSError errorWithDomain:NSStringFromClass([self class])
							   code:43421
						   userInfo:@{
		NSLocalizedDescriptionKey : NSLocalizedString(@"Notice", @"Notice"),
		NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.")
	}];
}

- (NSString *)domain {
	return NSStringFromClass([self class]);
}

- (NSString *)identifier {
	return self.databaseConnection.identifier;
}

#pragma mark - Cell parsing

+ (id)objectValueForCString:(const char *)cStr
					 isNull:(BOOL)isNull
				   dataType:(MADDataType)dataType {
	if (isNull || cStr == NULL) {
		return [NSNull null];
	}

	switch (dataType) {
		case MADDataTypeBit: {
			if (cStr[0] == 't' || cStr[0] == 'T' || cStr[0] == '1') {
				return @YES;
			}
			return @NO;
		}

		case MADDataTypeInteger:
		case MADDataTypeShort:
		case MADDataTypeLong:
		case MADDataTypeLongLong:
		case MADDataTypeInt24: {
			long long val = strtoll(cStr, NULL, 10);
			return [[NSNumber alloc] initWithLongLong:val];
		}

		case MADDataTypeFloat:
		case MADDataTypeDouble: {
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			if (str == nil) return [NSNull null];
			// PostgreSQL money values format with a currency symbol and thousands
			// separators (e.g. "$1,234.50"); strip those before strtod.
			NSMutableString *clean = [[NSMutableString alloc] initWithCapacity:str.length];
			for (NSUInteger i = 0; i < str.length; i++) {
				unichar ch = [str characterAtIndex:i];
				if ((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == '+' || ch == 'e' || ch == 'E') {
					[clean appendFormat:@"%C", ch];
				}
			}
			return [[NSNumber alloc] initWithDouble:clean.doubleValue];
		}

		case MADDataTypeDecimal:
		case MADDataTypeNumber: {
			if (strcasecmp(cStr, "NaN") == 0 || strcasecmp(cStr, "Infinity") == 0 || strcasecmp(cStr, "-Infinity") == 0) {
				return [NSNull null];
			}
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			if (str == nil || str.length == 0) return [NSNull null];
			NSDecimalNumber *decimal = [NSDecimalNumber decimalNumberWithString:str];
			if (decimal == nil || [decimal isEqualToNumber:[NSDecimalNumber notANumber]]) {
				return [NSNull null];
			}
			return decimal;
		}

		case MADDataTypeDate: {
			int year = 0, month = 0, day = 0;
			if (sscanf(cStr, "%d-%d-%d", &year, &month, &day) == 3) {
				NSDateComponents *comps = [[NSDateComponents alloc] init];
				comps.year = year;
				comps.month = month;
				comps.day = day;
				return comps;
			}
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			return str ?: [NSNull null];
		}

		case MADDataTypeTime: {
			int hour = 0, minute = 0, second = 0;
			if (sscanf(cStr, "%d:%d:%d", &hour, &minute, &second) >= 2) {
				NSDateComponents *comps = [[NSDateComponents alloc] init];
				comps.hour = hour;
				comps.minute = minute;
				comps.second = second;
				return comps;
			}
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			return str ?: [NSNull null];
		}

		case MADDataTypeDateTime:
		case MADDataTypeTimeStamp: {
			int year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0;
			int matched = sscanf(cStr, "%d-%d-%d %d:%d:%d", &year, &month, &day, &hour, &minute, &second);
			if (matched < 3) {
				matched = sscanf(cStr, "%d-%d-%dT%d:%d:%d", &year, &month, &day, &hour, &minute, &second);
			}
			if (matched >= 3) {
				NSDateComponents *comps = [[NSDateComponents alloc] init];
				comps.year = year;
				comps.month = month;
				comps.day = day;
				comps.hour = hour;
				comps.minute = minute;
				comps.second = second;
				return comps;
			}
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			return str ?: [NSNull null];
		}

		case MADDataTypeBlob:
		case MADDataTypeImage: {
			if (cStr[0] == '\\' && (cStr[1] == 'x' || cStr[1] == 'X')) {
				const char *hex = cStr + 2;
				size_t hexLen = strlen(hex);
				size_t byteLen = hexLen / 2;
				uint8_t *bytes = (uint8_t *)malloc(byteLen > 0 ? byteLen : 1);
				if (bytes == NULL) return [NSNull null];
				for (size_t i = 0; i < byteLen; i++) {
					int hi = MADHexNibble(hex[i * 2]);
					int lo = MADHexNibble(hex[i * 2 + 1]);
					bytes[i] = (uint8_t)(((hi >= 0 ? hi : 0) << 4) | (lo >= 0 ? lo : 0));
				}
				return [[NSData alloc] initWithBytesNoCopy:bytes length:byteLen freeWhenDone:YES];
			}
			size_t unescapedLen = 0;
			unsigned char *unescaped = PQunescapeBytea((const unsigned char *)cStr, &unescapedLen);
			if (unescaped != NULL) {
				NSData *data = [[NSData alloc] initWithBytes:unescaped length:unescapedLen];
				PQfreemem(unescaped);
				return data;
			}
			return [[NSData alloc] initWithBytes:cStr length:strlen(cStr)];
		}

		case MADDataTypeString:
		case MADDataTypeVarChar:
		case MADDataTypeEnum:
		case MADDataTypeSet:
		case MADDataTypeYear:
		case MADDataTypeGeometry:
		case MADDataTypeUnknown:
		case MADDataTypeNull:
		default: {
			NSString *str = [[NSString alloc] initWithUTF8String:cStr];
			if (str == nil) {
				str = [[NSString alloc] initWithCString:cStr encoding:NSISOLatin1StringEncoding];
			}
			return str ?: @"";
		}
	}
}

#pragma mark - Connection lifecycle

- (id)connectWithConnection:(MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)connection
				 credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error {
	if (credentals == nil) {
		credentals = [self credentalsWithConnection:connection];
	}

	if (connection == nil || credentals == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:1001
									 userInfo:@{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Error", @"Error"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Missing connection or credentials.", @"Missing connection or credentials."),
			}];
		}
		return nil;
	}

	MADPostgresConnection *pgConn = [[MADPostgresConnection alloc] init];
	NSError *connError = nil;
	BOOL ok = [pgConn connectWithHost:[connection server]
								 port:(int32_t)connection.port
								 user:credentals.username
							 password:credentals.password
							 database:connection.database
								error:&connError];
	self.liveConnection = ok ? pgConn : nil;
	if (!ok) {
		if (error != NULL) {
			*error = [connError copy];
		}
		if (connError != nil) {
			[self.errors insertObject:connError atIndex:0];
		}
		return nil;
	}
	return pgConn;
}

- (void)closeConnection:(id)process {
	if (process == self.liveConnection) {
		self.liveConnection = nil;
	}
	if ([process isKindOfClass:[MADPostgresConnection class]]) {
		[(MADPostgresConnection *)process disconnect];
	}
}

#pragma mark - Schema discovery

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
	id connectionSettings = self.databaseConnection;
	NSError * __autoreleasing connectionError = nil;
	MADPostgresConnection *conn = [self connectWithConnection:connectionSettings
												   credentals:nil
											  connectionError:&connectionError];
	if (conn != nil && connectionError == nil) {
		NSError *fetchError = nil;
		NSArray<MADDatabaseTable *> *tables = [self getTablesFromConnection:conn error:&fetchError];
		[self closeConnection:conn];
		if (completion) {
			completion(fetchError == nil, fetchError, tables);
		}
	} else {
		if (completion) {
			completion(NO, connectionError, nil);
		}
	}
}

- (void)getTablesFromConnection:(id)dbconn
					 completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [self getTablesFromConnection:dbconn error:&error];
	if (completion) {
		completion(error == nil, error, tables);
	}
}

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
													error:(NSError * __autoreleasing *)outError {
	if (![dbconn isKindOfClass:[MADPostgresConnection class]] || ![(MADPostgresConnection *)dbconn isConnected]) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:[self domain]
											code:3492
										userInfo:@{
				NSLocalizedDescriptionKey : @"Connection is empty.",
				NSLocalizedFailureReasonErrorKey : @"Connection Error"
			}];
		}
		return @[];
	}

	MADPostgresConnection *conn = (MADPostgresConnection *)dbconn;
	const char *sql =
		"SELECT CASE WHEN table_schema = 'public' THEN table_name "
		"            ELSE table_schema || '.' || table_name END AS qualified_name "
		"FROM information_schema.tables "
		"WHERE table_schema NOT IN ('pg_catalog', 'information_schema') "
		"  AND table_schema NOT LIKE 'pg_toast%' "
		"  AND table_type IN ('BASE TABLE', 'VIEW') "
		"ORDER BY CASE WHEN table_schema = 'public' THEN 0 ELSE 1 END, table_schema, table_name;";

	PGresult *res = PQexec(conn.pgConn, sql);
	ExecStatusType status = res != NULL ? PQresultStatus(res) : PGRES_FATAL_ERROR;
	if (status != PGRES_TUPLES_OK) {
		const char *errText = res != NULL ? PQresultErrorMessage(res) : PQerrorMessage(conn.pgConn);
		NSString *msg = (errText != NULL && errText[0] != '\0')
			? [[NSString alloc] initWithUTF8String:errText]
			: @"Failed to query tables.";
		if (res != NULL) PQclear(res);
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:[self domain]
											code:934
										userInfo:@{
				NSLocalizedDescriptionKey : msg ?: @"Failed to query tables."
			}];
		}
		return @[];
	}

	int rowCount = PQntuples(res);
	NSMutableArray<MADDatabaseTable *> *results = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)rowCount];
	for (int row = 0; row < rowCount; row++) {
		if (!PQgetisnull(res, row, 0)) {
			const char *cName = PQgetvalue(res, row, 0);
			if (cName != NULL) {
				NSString *tableName = [[NSString alloc] initWithUTF8String:cName];
				if (tableName.length > 0) {
					MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
					[results addObject:table];
				}
			}
		}
	}
	PQclear(res);
	return results;
}

- (void)enumerateTablesFromConnection:(id)dbconn
						   usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
						   completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [self getTablesFromConnection:dbconn error:&error];
	NSMutableArray<MADDatabaseTable *> *visited = nil;
	if (error == nil) {
		visited = [[NSMutableArray alloc] initWithCapacity:tables.count];
		BOOL stop = NO;
		NSUInteger idx = 0;
		for (MADDatabaseTable *table in tables) {
			[visited addObject:table];
			if (block != nil) {
				block(table, idx, &stop);
			}
			if (stop) break;
			idx++;
		}
	}
	if (completion) {
		completion(error == nil, error, visited);
	}
}

- (NSArray<MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
									 connection:(id)dbconn
										  error:(NSError * __autoreleasing *)error {
	if (tableName.length == 0 ||
		![dbconn isKindOfClass:[MADPostgresConnection class]] ||
		![(MADPostgresConnection *)dbconn isConnected]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:3492
									 userInfo:@{
				NSLocalizedDescriptionKey : @"Connection is empty.",
				NSLocalizedFailureReasonErrorKey : @"Connection Error"
			}];
		}
		return @[];
	}

	MADPostgresConnection *conn = (MADPostgresConnection *)dbconn;
	NSString *schemaName = nil;
	NSString *bareTable = nil;
	MADSplitPostgresTableName(tableName, &schemaName, &bareTable);

	const char *sql =
		"SELECT a.attname AS column_name, "
		"       a.atttypid::int AS type_oid, "
		"       COALESCE(c.character_maximum_length, c.numeric_precision, a.attlen, 0) AS width, "
		"       COALESCE(c.numeric_scale, 0) AS scale, "
		"       EXISTS ("
		"           SELECT 1 FROM pg_index i "
		"           WHERE i.indrelid = a.attrelid "
		"             AND i.indisprimary "
		"             AND a.attnum = ANY(i.indkey)"
		"       ) AS is_primary "
		"FROM pg_attribute a "
		"JOIN pg_class cls ON cls.oid = a.attrelid "
		"JOIN pg_namespace ns ON ns.oid = cls.relnamespace "
		"LEFT JOIN information_schema.columns c "
		"       ON c.table_schema = ns.nspname "
		"      AND c.table_name = cls.relname "
		"      AND c.column_name = a.attname "
		"WHERE ns.nspname = $1 "
		"  AND cls.relname = $2 "
		"  AND a.attnum > 0 "
		"  AND NOT a.attisdropped "
		"ORDER BY a.attnum;";

	const char *paramValues[2] = {
		schemaName.UTF8String,
		bareTable.UTF8String
	};

	PGresult *res = PQexecParams(conn.pgConn, sql, 2, NULL, paramValues, NULL, NULL, 0);
	ExecStatusType status = res != NULL ? PQresultStatus(res) : PGRES_FATAL_ERROR;
	if (status != PGRES_TUPLES_OK) {
		const char *errText = res != NULL ? PQresultErrorMessage(res) : PQerrorMessage(conn.pgConn);
		NSString *msg = (errText != NULL && errText[0] != '\0')
			? [[NSString alloc] initWithUTF8String:errText]
			: @"Failed to query table fields.";
		if (res != NULL) PQclear(res);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:3456
									 userInfo:@{
				NSLocalizedDescriptionKey : msg ?: @"Failed to query table fields."
			}];
		}
		return @[];
	}

	int rowCount = PQntuples(res);
	NSMutableArray<MADDatabaseField *> *fields = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)rowCount];
	for (int row = 0; row < rowCount; row++) {
		const char *cName = PQgetvalue(res, row, 0);
		if (cName == NULL) continue;
		NSString *colName = [[NSString alloc] initWithUTF8String:cName];
		if (colName.length == 0) continue;

		unsigned int typeOid = (unsigned int)strtoul(PQgetvalue(res, row, 1) ?: "0", NULL, 10);
		long long width = strtoll(PQgetvalue(res, row, 2) ?: "0", NULL, 10);
		int scale = (int)strtol(PQgetvalue(res, row, 3) ?: "0", NULL, 10);
		const char *pkStr = PQgetvalue(res, row, 4);
		BOOL isPrimary = (pkStr != NULL && (pkStr[0] == 't' || pkStr[0] == 'T' || pkStr[0] == '1'));

		MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:colName];
		MADDataType mappedType = [MADDataTypePostgres madDataTypeFromPostgresOID:typeOid];
		field.fieldType = mappedType;
		field.fieldTypeNative = (int16_t)mappedType;
		field.width = (int64_t)(width > 0 ? width : 0);
		field.decimals = (int16_t)(scale > 0 ? scale : 0);
		field.primaryKey = isPrimary;
		[fields addObject:field];
	}
	PQclear(res);
	return fields;
}

#pragma mark - Query execution

- (BOOL)executeSQL:(NSString *)sql
		 fieldKeys:(NSArray *)fieldKeys
	  onConnection:(id)dbconn
   intoResultTable:(id <MADDataTableWriting>)dataTable
		 withError:(NSError * __autoreleasing *)error {
	BOOL ok = [self runSQL:sql
				 fieldKeys:fieldKeys
			  onConnection:dbconn
		   intoResultTable:dataTable
				 withError:error];
	if (dbconn == self.liveConnection) {
		self.liveConnection = nil;
	}
	return ok;
}

- (BOOL)runSQL:(NSString *)sql
	 fieldKeys:(NSArray *)fieldKeys
  onConnection:(id)dbconn
intoResultTable:(id <MADDataTableWriting>)dataTable
	 withError:(NSError * __autoreleasing *)error {
	if (![dbconn isKindOfClass:[MADPostgresConnection class]] ||
		![(MADPostgresConnection *)dbconn isConnected] ||
		sql.length == 0 ||
		dataTable == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:3492
									 userInfo:@{
				NSLocalizedDescriptionKey : @"Connection is empty.",
				NSLocalizedFailureReasonErrorKey : @"Connection Error"
			}];
		}
		return NO;
	}

	MADPostgresConnection *conn = (MADPostgresConnection *)dbconn;
	PGresult *res = PQexec(conn.pgConn, sql.UTF8String);
	ExecStatusType status = res != NULL ? PQresultStatus(res) : PGRES_FATAL_ERROR;

	if (status != PGRES_TUPLES_OK && status != PGRES_COMMAND_OK) {
		const char *errText = res != NULL ? PQresultErrorMessage(res) : PQerrorMessage(conn.pgConn);
		NSString *msg = (errText != NULL && errText[0] != '\0')
			? [[NSString alloc] initWithUTF8String:errText]
			: @"PostgreSQL query execution failed.";
		if (res != NULL) PQclear(res);
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:4534
									 userInfo:@{
				NSLocalizedDescriptionKey : msg ?: @"PostgreSQL query execution failed.",
				NSLocalizedFailureReasonErrorKey : msg ?: @"PostgreSQL query execution failed."
			}];
		}
		return NO;
	}

	[dataTable removeAllObjects];

	if (status == PGRES_TUPLES_OK) {
		int numFields = PQnfields(res);
		int numRows = PQntuples(res);
		NSMutableArray<NSString *> *columnNames = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)numFields];
		NSMutableArray<NSNumber *> *columnTypes = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)numFields];

		for (int col = 0; col < numFields; col++) {
			NSString *fieldName = nil;
			if (fieldKeys != nil && (NSUInteger)col < fieldKeys.count) {
				fieldName = fieldKeys[(NSUInteger)col];
			} else {
				const char *cColName = PQfname(res, col);
				fieldName = (cColName != NULL)
					? [[NSString alloc] initWithUTF8String:cColName]
					: [[NSString alloc] initWithFormat:@"col_%d", col];
			}
			if (fieldName == nil) {
				fieldName = [[NSString alloc] initWithFormat:@"col_%d", col];
			}

			Oid colOid = PQftype(res, col);
			MADDataType colDataType = [MADDataTypePostgres madDataTypeFromPostgresOID:colOid];
			int colSize = PQfsize(res, col);
			int colMod = PQfmod(res, col);

			MADDataColumn *dataColumn = [[MADDataColumn alloc] initWithIdentifier:fieldName];
			dataColumn.fieldName = fieldName;
			dataColumn.type = colDataType;
			dataColumn.nativeType = (int16_t)colDataType;
			dataColumn.dataLength = colSize > 0 ? colSize : (colMod > 4 ? colMod - 4 : 0);
			dataColumn.dataPercision = 0;
			[dataTable addColumn:dataColumn];

			[columnNames addObject:fieldName];
			[columnTypes addObject:@(colDataType)];
		}

		if ([dataTable respondsToSelector:@selector(beginBulkInsert)]) {
			[dataTable beginBulkInsert];
		}

		for (int row = 0; row < numRows; row++) {
			[self readRow:(NSUInteger)row];
			@autoreleasepool {
				NSMutableDictionary<NSString *, id> *rowDict =
					[[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)numFields];
				for (int col = 0; col < numFields; col++) {
					NSString *key = columnNames[(NSUInteger)col];
					MADDataType colType = (MADDataType)columnTypes[(NSUInteger)col].shortValue;
					BOOL isNull = PQgetisnull(res, row, col) != 0;
					const char *cVal = isNull ? NULL : PQgetvalue(res, row, col);
					id obj = [MADDatabasePostgres objectValueForCString:cVal
																 isNull:isNull
															   dataType:colType];
					rowDict[key] = obj ?: [NSNull null];
				}
				[dataTable addRowWithDataForFieldKeys:rowDict];
			}
		}

		if ([dataTable respondsToSelector:@selector(endBulkInsert)]) {
			[dataTable endBulkInsert];
		}
	}

	PQclear(res);
	return YES;
}

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error {
	id <MADDatabaseResultsProtocol> delegate = self.delegate;
	MADDataTable *dataTable = nil;
	if ([query conformsToProtocol:@protocol(MADQueryDataTableProtocol)] &&
		((MADQuery <MADQueryDataTableProtocol> *)query).dataTable != nil) {
		dataTable = ((MADQuery <MADQueryDataTableProtocol> *)query).dataTable;
	} else if ([delegate respondsToSelector:@selector(dataTableForQuery:)]) {
		dataTable = [delegate dataTableForQuery:query];
	}
	NSError *executeError = nil;
	BOOL result = [self executeQuery:query withDataTable:dataTable andError:&executeError];
	if (executeError != nil && error != NULL) {
		*error = [executeError copy];
	}
	return result;
}

- (BOOL)executeQuery:(MADQuery *)query
	   withDataTable:(id <MADDataTableWriting>)dataTable
			andError:(NSError * __autoreleasing *)error {
	if (query == nil || dataTable == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:[self domain]
										 code:3492
									 userInfo:@{
				NSLocalizedDescriptionKey : @"Missing query or destination table.",
				NSLocalizedFailureReasonErrorKey : @"Query Error"
			}];
		}
		return NO;
	}

	id connectionSettings = self.databaseConnection;
	NSError * __autoreleasing dberror = nil;
	MADCredential *cred = nil;
	if ([query conformsToProtocol:@protocol(MADQueryCredentialProtocol)]) {
		cred = [((MADQuery <MADQueryCredentialProtocol> *)query).credential copy];
	}

	MADPostgresConnection *dbconn = [self connectWithConnection:connectionSettings
													 credentals:cred
												connectionError:&dberror];
	if (dbconn == nil || dberror != nil) {
		if (dberror != nil && error != NULL) {
			*error = [dberror copy];
		}
		return NO;
	}

	NSError * __autoreleasing sqlError = nil;
	NSString *queryString = [query getSql:self error:&sqlError];
	BOOL result = NO;
	if (queryString != nil && queryString.length > 0 && sqlError == nil) {
		NSArray *fieldKeys = [query conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)]
			? ((MADQuery <MADQueryFieldKeysProtocol> *)query).fieldKeys
			: nil;
		result = [self runSQL:queryString
					fieldKeys:fieldKeys
				 onConnection:dbconn
			  intoResultTable:dataTable
					withError:&sqlError];
	}

	[self closeConnection:dbconn];

	if (!result && sqlError != nil && error != NULL) {
		*error = [sqlError copy];
	}
	return result;
}

@end
