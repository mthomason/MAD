//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIServe.m
//  MAD Designer
//
//  `mad serve` -- the long-lived process boundary the Windows shell speaks (the
//  WPF app's engine; docs/developers/build/windows.md §Phase 4).  It reads newline-delimited
//  JSON requests on standard input and writes one newline-delimited JSON response
//  per request on standard output.  Standard output carries only the protocol;
//  every diagnostic already goes to standard error (madlog, MADCLIError), so the
//  two never mix.
//
//  The wire shape reuses the project's existing JSON contract rather than inventing
//  a parallel one.  `export` with `format` "json" returns the exact bytes
//  `mad export --format json` writes (the `mad.report/1` object, MADReportExporterJSON),
//  and `export` with "csv" the exact RFC 4180 bytes -- both through the export seam
//  (MADReportExporting / MADReportExporterRegistry) and MADReportExportSource, which
//  is the one place a document is read as columns and rows.  `describe` returns those
//  same columns plus the stored database schema (the tables/fields `mad schema`
//  prints), and `query`/`refresh`/`write` are the one-shot verbs' own data paths.
//
//  Request:   { "id": <int|string>, "method": "<name>", "params": { ... } }
//  Response:  { "id": <id>, "ok": true,  "result": { ... } }
//  Response:  { "id": <id>, "ok": false, "error": { "code": <int>, "message": "..." } }
//
//  Error `code` is the CLI's exit code (MADCLI.h): 1 usage/protocol, 2 bad document,
//  3 database unreachable, 4 query failed, 5 export failed.  A malformed request,
//  an unknown method, a missing parameter and an unexpected engine exception all
//  answer `ok: false` with a message -- never a traceback -- and the session keeps
//  running.  `shutdown` (or end-of-file on standard input) ends the session and the
//  process exits 0.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADReportExporting.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExportSource.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDocumentSectionRows+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataType.h>

#import <MAD/MADDatabase+Constructor.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADSQLParser.h>
#import <MAD/MADSQLStatementResolver.h>
#import <MAD/MADSQLQueryCompiler.h>

#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementImage+Extras.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MADBarcodes/MADBarcode.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAlignment.h>
#import <MAD/MTPaper.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqPoint.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqAlignment.h>

#if defined(_WIN32)
#include <io.h>
#include <fcntl.h>
#endif

static NSString * const MADCLIServeMethodOpen		= @"open";
static NSString * const MADCLIServeMethodDescribe	= @"describe";
static NSString * const MADCLIServeMethodQuery		= @"query";
static NSString * const MADCLIServeMethodRefresh	= @"refresh";
static NSString * const MADCLIServeMethodExport		= @"export";
static NSString * const MADCLIServeMethodNodeResult	= @"node-result";
static NSString * const MADCLIServeMethodWrite		= @"write";
static NSString * const MADCLIServeMethodShutdown	= @"shutdown";
static NSString * const MADCLIServeMethodCreate			= @"create";
static NSString * const MADCLIServeMethodTestConnection	= @"test-connection";
static NSString * const MADCLIServeMethodConnection		= @"connection";
static NSString * const MADCLIServeMethodApplyConnection	= @"apply-connection";
static NSString * const MADCLIServeMethodQueryModel	= @"query-model";
static NSString * const MADCLIServeMethodAddTable		= @"add-table";
static NSString * const MADCLIServeMethodRemoveTable	= @"remove-table";
static NSString * const MADCLIServeMethodAddLink		= @"add-link";
static NSString * const MADCLIServeMethodSetLinkType	= @"set-link-type";
static NSString * const MADCLIServeMethodSwapLink		= @"swap-link";
static NSString * const MADCLIServeMethodDeleteLink	= @"delete-link";
static NSString * const MADCLIServeMethodAddPredicate	= @"add-predicate";
static NSString * const MADCLIServeMethodRemovePredicate = @"remove-predicate";
static NSString * const MADCLIServeMethodAddGroup		= @"add-group";
static NSString * const MADCLIServeMethodRemoveGroup	= @"remove-group";
static NSString * const MADCLIServeMethodValidateSQL	= @"validate-sql";
static NSString * const MADCLIServeMethodApplySQL		= @"apply-sql";
static NSString * const MADCLIServeMethodLayoutModel	= @"layout-model";
static NSString * const MADCLIServeMethodAddElement		= @"add-element";
static NSString * const MADCLIServeMethodRemoveElements	= @"remove-elements";
static NSString * const MADCLIServeMethodDuplicateElements = @"duplicate-elements";
static NSString * const MADCLIServeMethodMoveElements	= @"move-elements";
static NSString * const MADCLIServeMethodSetElementGeometry = @"set-element-geometry";
static NSString * const MADCLIServeMethodSetElementContent = @"set-element-content";
static NSString * const MADCLIServeMethodSetElementTypography = @"set-element-typography";
static NSString * const MADCLIServeMethodSetElementBoxModel = @"set-element-box-model";
static NSString * const MADCLIServeMethodSetSection		= @"set-section";
static NSString * const MADCLIServeMethodSetPaperSize	= @"set-paper-size";
static NSString * const MADCLIServeMethodBarcodeTypes	= @"barcode-types";
static NSString * const MADCLIServeMethodEngineInfo	= @"engine-info";
static NSString * const MADCLIServeMethodDocumentInfo	= @"document-info";
static NSString * const MADCLIServeMethodAddRoot			= @"add-root";
static NSString * const MADCLIServeMethodAddSource		= @"add-source";
static NSString * const MADCLIServeMethodAddUpstream	= @"add-upstream";
static NSString * const MADCLIServeMethodImportChild	= @"import-child";
static NSString * const MADCLIServeMethodConvert		= @"convert";
static NSString * const MADCLIServeMethodSetRootOutputs	= @"set-root-outputs";
static NSString * const MADCLIServeMethodCreateEmpty	= @"create-empty";

#pragma mark - Session state

/// One opened document, by integer handle.  The document is the same MADCLIDocument
/// the one-shot verbs use (MADHeadlessDocument underneath, off Apple); the source URL
/// is kept so `write` can re-open and copy the file the way `mad write` does.
@interface MADCLIServeDocument : NSObject
@property (nonatomic, strong) MADCLIDocument *document;
@property (nonatomic, copy) NSURL *sourceURL;
@end

@implementation MADCLIServeDocument
@end

#pragma mark - Line and JSON plumbing

/// Reads one line from standard input, without the trailing newline.  Tolerates CRLF
/// (a bare CR is dropped).  Returns a malloc'd buffer, or NULL at end-of-file.
static char *MADCLIServeReadLine(void) {
	size_t capacity = 256;
	size_t length = 0;
	char *buffer = (char *)malloc(capacity);
	if (buffer == NULL) return NULL;
	int c;
	while ((c = fgetc(stdin)) != EOF) {
		if (c == '\n') break;
		if (c == '\r') continue;
		if (length + 1 >= capacity) {
			capacity *= 2;
			char *grown = (char *)realloc(buffer, capacity);
			if (grown == NULL) { free(buffer); return NULL; }
			buffer = grown;
		}
		buffer[length++] = (char)c;
	}
	if (c == EOF && length == 0) { free(buffer); return NULL; }
	buffer[length] = '\0';
	return buffer;
}

/// Serialize an object to compact JSON (no embedded newlines, so one response is one
/// line).  Falls back to a hand-written error when serialization itself fails.
static NSData *MADCLIServeJSONData(id object) {
	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject: object options: 0 error: &error];
	if (data != nil) return data;
	return [@"{\"ok\":false,\"error\":{\"code\":1,\"message\":\"could not encode the response\"}}"
			dataUsingEncoding: NSUTF8StringEncoding];
}

static void MADCLIServeWrite(id requestID, NSDictionary *response) {
	NSData *data = MADCLIServeJSONData(response);
	fwrite(data.bytes, 1, data.length, stdout);
	fwrite("\n", 1, 1, stdout);
	fflush(stdout);
}

static void MADCLIServeWriteResult(id requestID, NSDictionary *result) {
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	response[@"id"] = requestID ?: [NSNull null];
	response[@"ok"] = @YES;
	response[@"result"] = result ?: @{};
	MADCLIServeWrite(requestID, response);
}

static void MADCLIServeWriteError(id requestID, NSInteger code, NSString *message) {
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	response[@"id"] = requestID ?: [NSNull null];
	response[@"ok"] = @NO;
	response[@"error"] = @{ @"code": @(code), @"message": message ?: @"error" };
	MADCLIServeWrite(requestID, response);
}

#pragma mark - Small helpers

/// The stored driver identifier ("Sqlite 3", "MySQL", "TDS"), the same first-schema
/// read MADReportExportSource.driverNameForDocument: performs.
static NSString *MADCLIServeDriverName(id <MADDocumentDataProtocol> document) {
	for (RptqDatabase *schema in document.activeDocumentModel.hasDatabaseSchemas) {
		if (schema.databaseDriverType.length > 0) {
			return schema.databaseDriverType;
		}
	}
	return @"";
}

/// The stored data type as a stable token ("String", "Integer"), never the localized
/// +dataTypeDisplay: (MADReportExportSource makes the same choice).
static NSString *MADCLIServeTypeName(MADDataType type) {
	NSString *name = NSStringFromMADDataType(type);
	static NSString * const prefix = @"MADDataType";
	if ([name hasPrefix: prefix]) {
		return [name substringFromIndex: prefix.length];
	}
	return name;
}

/// A parameter that must be a string; nil (with a filled error) when it is not.
static NSString *MADCLIServeStringParam(NSDictionary *params, NSString *key, NSError **error) {
	id value = params[key];
	if ([value isKindOfClass: [NSString class]]) return value;
	if (error) {
		*error = [NSError errorWithDomain: @"MADCLI"
									 code: MADCLIExitUsage
								 userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: @"%@ must be a string.", key] }];
	}
	return nil;
}

static NSError *MADCLIServeUsageError(NSString *message) {
	return [NSError errorWithDomain: @"MADCLI"
							   code: MADCLIExitUsage
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}

/// Parse "user:password" into a MADCredential, the same split the refresh verb makes.
static MADCredential *MADCLIServeCredential(NSString *credentials, NSError **error) {
	if (credentials.length == 0) return nil;
	NSRange colon = [credentials rangeOfString: @":"];
	if (colon.location == NSNotFound) {
		if (error) *error = MADCLIServeUsageError(@"credentials wants user:password.");
		return nil;
	}
	return [[MADCredential alloc]
			initWithUsername: [credentials substringToIndex: colon.location]
			andPassword: [credentials substringFromIndex: colon.location + 1]];
}

/// Parses `sourceCredentials`, an object keyed by a query id (as a decimal string)
/// whose value is that source's `user:password`.  It is the per-source form of
/// `refresh`; the single `credentials` member stays the fallback.  Answers nil with
/// no error when the member is absent, and nil with a usage error when it is malformed.
static NSDictionary<NSNumber *, MADCredential *> *MADCLIServeSourceCredentials(NSDictionary *params, NSError **error) {
	id raw = params[@"sourceCredentials"];
	if (raw == nil) return nil;
	if (![raw isKindOfClass: [NSDictionary class]]) {
		if (error) *error = MADCLIServeUsageError(@"sourceCredentials must be an object keyed by query id.");
		return nil;
	}
	NSMutableDictionary<NSNumber *, MADCredential *> *credentials = [NSMutableDictionary dictionary];
	for (id key in (NSDictionary *)raw) {
		if (![key isKindOfClass: [NSString class]] || [(NSString *)key longLongValue] <= 0) {
			if (error) *error = MADCLIServeUsageError(@"sourceCredentials keys must be decimal query ids.");
			return nil;
		}
		id value = ((NSDictionary *)raw)[key];
		if (![value isKindOfClass: [NSString class]]) {
			if (error) *error = MADCLIServeUsageError(@"sourceCredentials values must be user:password strings.");
			return nil;
		}
		MADCredential *credential = MADCLIServeCredential(value, error);
		if (credential == nil) return nil;
		credentials[@([(NSString *)key longLongValue])] = credential;
	}
	return credentials;
}

/// Maps the connection window's wire driver token to a MADDatabaseType.  "sqlserver"
/// is the wire name for the TDS driver (Microsoft SQL Server).
static MADDatabaseType MADCLIServeDatabaseTypeForToken(NSString *token) {
	if ([token isEqualToString: @"sqlite3"]) return MADDatabaseTypeSqlite3;
	if ([token isEqualToString: @"mysql"]) return MADDatabaseTypeMySQL;
	if ([token isEqualToString: @"sqlserver"]) return MADDatabaseTypeTDS;
	if ([token isEqualToString: @"postgres"]) return MADDatabaseTypePostgres;
	return MADDatabaseTypeNotSet;
}

static NSString *MADCLIServeTokenForDatabaseType(MADDatabaseType type) {
	switch (type) {
		case MADDatabaseTypeSqlite3: return @"sqlite3";
		case MADDatabaseTypeMySQL: return @"mysql";
		case MADDatabaseTypeTDS: return @"sqlserver";
		case MADDatabaseTypePostgres: return @"postgres";
		default: return @"";
	}
}

/// A trimmed, non-empty string parameter, or nil when absent/empty.
static NSString *MADCLIServeOptionalString(NSDictionary *params, NSString *key) {
	id value = params[key];
	if (![value isKindOfClass: [NSString class]]) return nil;
	NSString *string = [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return string.length > 0 ? string : nil;
}

/// Builds a MADDatabaseConnection from the connection window's params, mirroring
/// MADMacConnectionWindowController -buildConnectionWithCredentials:error:.  Answers
/// nil and fills `error` (code 1) on invalid settings, and hands the parsed
/// `user:password` credential back through `outCredentials`.
static MADDatabaseConnection *MADCLIServeBuildConnection(NSDictionary *params, MADCredential **outCredentials, NSError **error) {
	NSString *driverToken = MADCLIServeOptionalString(params, @"driver");
	MADDatabaseType type = MADCLIServeDatabaseTypeForToken(driverToken);
	if (type == MADDatabaseTypeNotSet) {
		if (error) *error = MADCLIServeUsageError([NSString stringWithFormat: @"unknown driver '%@'.", driverToken ?: @""]);
		return nil;
	}

	if (type == MADDatabaseTypeSqlite3) {
		NSString *file = MADCLIServeOptionalString(params, @"file");
		if (file.length == 0) {
			if (error) *error = MADCLIServeUsageError(@"Please choose an existing SQLite database file.");
			return nil;
		}
		if (outCredentials) *outCredentials = nil;
		// The connect step (not this builder) reports a missing or 0-byte file as
		// a database-unreachable error, the way MADDatabaseSqlite3 does natively.
		return [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: [NSURL fileURLWithPath: file isDirectory: NO]];
	}

	NSString *host = MADCLIServeOptionalString(params, @"host");
	NSString *database = MADCLIServeOptionalString(params, @"database");
	if (host.length == 0 || database.length == 0) {
		if (error) *error = MADCLIServeUsageError(@"Host and Database Name are required.");
		return nil;
	}

	MADCredential *credentials = nil;
	NSString *credentialsParam = MADCLIServeOptionalString(params, @"credentials");
	if (credentialsParam.length > 0) {
		credentials = MADCLIServeCredential(credentialsParam, error);
		if (credentials == nil) return nil;
	}
	if (outCredentials) *outCredentials = credentials;

	NSInteger port = [params[@"port"] isKindOfClass: [NSNumber class]] ? [params[@"port"] integerValue] : 0;

	switch (type) {
		case MADDatabaseTypeMySQL:
			return [[MADDatabaseConnectionMySql alloc] initWithHost: host database: database andPort: (port > 0 ? port : 3306)];
		case MADDatabaseTypeTDS: {
			NSString *server = MADCLIServeOptionalString(params, @"server");
			if (server.length == 0) server = host;
			return [[MADDatabaseConnectionSQLServer alloc] initWithHost: host server: server database: database andPort: (port > 0 ? port : 1433)];
		}
		case MADDatabaseTypePostgres:
			return [[MADDatabaseConnectionPostgres alloc] initWithHost: host database: database andPort: (port > 0 ? port : 5432)];
		default:
			return nil;
	}
}

#pragma mark - Method handlers

/// The column list for a document, in the exact shape the JSON export writes
/// (`mad.report/1`'s `columns`): key, name, table and type.  A document whose query
/// produces no SQL yields an empty list rather than an error -- it still has a stored
/// schema to describe.
static NSArray <NSDictionary *> *MADCLIServeColumnsForSource(MADReportExportSource *source) {
	NSMutableArray <NSDictionary *> *columns = [NSMutableArray array];
	for (NSString *key in source.columnKeys) {
		NSMutableDictionary *column = [NSMutableDictionary dictionary];
		column[@"key"] = key;
		column[@"name"] = [source columnName: key] ?: key;
		column[@"table"] = [source columnTable: key] ?: [NSNull null];
		column[@"type"] = [source columnType: key] ?: [NSNull null];
		[columns addObject: column];
	}
	return columns;
}

static NSArray <NSDictionary *> *MADCLIServeColumns(id <MADDocumentDataProtocol> document) {
	NSError *error = nil;
	MADReportExportSource *source = [MADReportExportSource sourceWithDocument: document error: &error];
	return source != nil ? MADCLIServeColumnsForSource(source) : @[];
}

/// A query's output columns, from its own fields rather than a materialized result:
/// a composing node's ordered outputs (by outputKey), a leaf's per-table fields.
/// This is what `describe` with a `query` returns, so it works before any refresh.
static NSArray <NSDictionary *> *MADCLIServeColumnsForQuery(RptqQuery *query) {
	NSMutableArray <NSDictionary *> *columns = [NSMutableArray array];
	if ([query isComposing]) {
		for (RptqQueryField *field in [query orderedOutputFieldsWithError:NULL] ?: @[]) {
			NSString *key = field.outputKey ?: (field.databaseSchemaField.name ?: @"");
			NSString *table = field.inQueryTable.upstreamQuery.name ?: @"";
			[columns addObject: @{
				@"key": key,
				@"name": field.databaseSchemaField.name ?: @"",
				@"table": table.length > 0 ? table : [NSNull null],
				@"type": MADCLIServeTypeName(field.databaseSchemaField.dataType),
			}];
		}
	} else {
		for (RptqQueryTable *table in [query.hasQueryTables allObjects]) {
			NSString *alias = table.alias.length > 0 ? table.alias : (table.databaseSchemaTable.name ?: @"");
			for (RptqQueryField *field in table.hasQueryFields) {
				NSString *name = field.databaseSchemaField.name ?: @"";
				NSString *key = alias.length > 0 ? [NSString stringWithFormat:@"%@.%@", alias, name] : name;
				[columns addObject: @{
					@"key": key,
					@"name": name,
					@"table": alias.length > 0 ? alias : [NSNull null],
					@"type": MADCLIServeTypeName(field.databaseSchemaField.dataType),
				}];
			}
		}
	}
	return columns;
}

/// One database's schema, the same tables/fields `mad schema` prints, as JSON.
static NSArray <NSDictionary *> *MADCLIServeTablesForDatabase(RptqDatabase *schema) {
	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
	NSMutableArray <NSDictionary *> *tables = [NSMutableArray array];
	NSArray <RptqDatabaseSchemaTable *> *sorted =
		[[schema.hasTables allObjects] sortedArrayUsingDescriptors: @[byName]];
	for (RptqDatabaseSchemaTable *table in sorted) {
		NSMutableArray <NSDictionary *> *fields = [NSMutableArray array];
		for (RptqDatabaseSchemaField *field in table.hasFields) {
			[fields addObject: @{
				@"name": field.name ?: @"",
				@"type": MADCLIServeTypeName(field.dataType),
				@"primaryKey": @(field.primaryKey),
			}];
		}
		[tables addObject: @{ @"name": table.name ?: @"", @"fields": fields }];
	}
	return tables;
}

/// The stored database schema, the same tables/fields `mad schema` prints, as JSON.
static NSArray <NSDictionary *> *MADCLIServeTables(id <MADDocumentDataProtocol> document) {
	RptqDocument *model = document.activeDocumentModel;
	NSMutableArray <NSDictionary *> *tables = [NSMutableArray array];
	for (RptqDatabase *schema in model.hasDatabaseSchemas) {
		[tables addObjectsFromArray: MADCLIServeTablesForDatabase(schema)];
	}
	return tables;
}

/// A leaf query's own database schema (its `inDatabase` only -- not a sibling's).
static NSArray <NSDictionary *> *MADCLIServeTablesForQuery(RptqQuery *query) {
	RptqDatabase *database = query.inDatabase;
	return database != nil ? MADCLIServeTablesForDatabase(database) : @[];
}

static void MADCLIServeOpen(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	NSError *error = nil;
	NSString *path = MADCLIServeStringParam(params, @"path", &error);
	if (path == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	NSURL *url = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(path)];
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: url error: &error];
	if (cliDocument == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}

	// Apply --host/--port/--database overrides the way the one-shot verbs do, so one
	// checked-in document can run against a different server for this session only.
	NSString *host = [params[@"host"] isKindOfClass: [NSString class]] ? params[@"host"] : nil;
	NSString *databaseName = [params[@"database"] isKindOfClass: [NSString class]] ? params[@"database"] : nil;
	NSInteger port = [params[@"port"] isKindOfClass: [NSNumber class]] ? [params[@"port"] integerValue] : 0;

	MADCLIInvocation *overrides = [[MADCLIInvocation alloc] init];
	overrides.host = host.length > 0 ? host : nil;
	overrides.databaseName = databaseName.length > 0 ? databaseName : nil;
	overrides.port = port;
	if (!MADCLIApplyConnectionOverrides(overrides, cliDocument.document, &error)) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	NSInteger handle = 0;
	for (NSNumber *candidate in documents.allKeys) {
		if (candidate.integerValue >= handle) handle = candidate.integerValue + 1;
	}

	MADCLIServeDocument *entry = [[MADCLIServeDocument alloc] init];
	entry.document = cliDocument;
	entry.sourceURL = url;
	documents[@(handle)] = entry;

	MADCLIServeWriteResult(requestID, @{
		@"handle": @(handle),
		@"filename": url.lastPathComponent ?: @"",
		@"driver": MADCLIServeDriverName(cliDocument.document),
	});
}

static void MADCLIServeTestConnection(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	(void)documents;

	NSError *error = nil;
	MADCredential *credentials = nil;
	MADDatabaseConnection *connection = MADCLIServeBuildConnection(params, &credentials, &error);
	if (connection == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];
	id dbHandle = [database connectWithConnection: connection credentals: credentials connectionError: &error];
	if (dbHandle == nil || error != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}

	NSArray <MADDatabaseTable *> *tables = [database getTablesFromConnection: dbHandle error: &error];
	[database closeConnection: dbHandle];
	if (error != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}

	MADCLIServeWriteResult(requestID, @{ @"tableCount": @(tables.count) });
}

static void MADCLIServeCreate(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	NSError *error = nil;
	NSString *path = MADCLIServeStringParam(params, @"path", &error);
	if (path == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	MADCredential *credentials = nil;
	MADDatabaseConnection *connection = MADCLIServeBuildConnection(params, &credentials, &error);
	if (connection == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	NSURL *url = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(path)];
	NSError *directoryError = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtURL: [url URLByDeletingLastPathComponent]
									  withIntermediateDirectories: YES
														attributes: nil
															 error: &directoryError]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"create: cannot create %@: %@",
				[url URLByDeletingLastPathComponent].path, directoryError.localizedDescription]);
		return;
	}

	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL: url
													withDatabaseConnection: connection
															   credentials: credentials
																	 error: &error];
	if (document == nil) {
		// The failed create opened the portable store before connecting, which leaves
		// its guts directory in the temp dir. Remove it so a bad connection leaves no
		// artifact behind.
		[[NSFileManager defaultManager] removeItemAtURL: [MADDocumentStore storeForDocumentURL: url].gutsURL error: NULL];
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}

	NSInteger handle = 0;
	for (NSNumber *candidate in documents.allKeys) {
		if (candidate.integerValue >= handle) handle = candidate.integerValue + 1;
	}

	MADCLIDocument *cliDocument = [[MADCLIDocument alloc] initWithDocument: document];
	MADCLIServeDocument *entry = [[MADCLIServeDocument alloc] init];
	entry.document = cliDocument;
	entry.sourceURL = url;
	documents[@(handle)] = entry;

	MADCLIServeWriteResult(requestID, @{
		@"handle": @(handle),
		@"filename": url.lastPathComponent ?: @"",
		@"driver": MADCLIServeDriverName(document),
	});
}

static MADCLIServeDocument *MADCLIServeLookup(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID);

static void MADCLIServeConnection(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	MADDatabaseConnection *connection = document.database.databaseConnection;
	if (connection == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"the document has no source database connection.");
		return;
	}

	MADDatabaseType type = connection.databaseType;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"driver"] = MADCLIServeTokenForDatabaseType(type);

	if (type == MADDatabaseTypeSqlite3) {
		NSString *file = @"";
		if ([connection conformsToProtocol: @protocol(MADDatabaseConnectionsPropertiesURL)]) {
			NSURL *databaseURL = ((id <MADDatabaseConnectionsPropertiesURL>)connection).databaseUrl;
			file = databaseURL.path ?: @"";
		}
		result[@"file"] = file;
	} else if ([connection conformsToProtocol: @protocol(MADConnectionsPropertiesProtocol)]) {
		id <MADConnectionsPropertiesProtocol> serverConnection = (id <MADConnectionsPropertiesProtocol>)connection;
		result[@"host"] = serverConnection.host ?: @"";
		result[@"port"] = @(serverConnection.port);
		result[@"database"] = serverConnection.database ?: @"";
		if (type == MADDatabaseTypeTDS) {
			result[@"server"] = serverConnection.server ?: @"";
		}
	}

	MADCLIServeWriteResult(requestID, result);
}

static void MADCLIServeApplyConnection(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSError *error = nil;
	MADCredential *credentials = nil;
	MADDatabaseConnection *connection = MADCLIServeBuildConnection(params, &credentials, &error);
	if (connection == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	// Verify the new connection before applying it (the Mac's "Save & Refresh").
	MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];
	id dbHandle = [database connectWithConnection: connection credentals: credentials connectionError: &error];
	if (dbHandle == nil || error != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}
	[database closeConnection: dbHandle];

	id <MADDocumentDataProtocol> document = entry.document.document;
	// A composed source edits only its own database row; omitting `query` (a Standard
	// Report) reconnects the document as before.
	int64_t queryIdentifier = [params[@"query"] isKindOfClass: [NSNumber class]]
		? [params[@"query"] longLongValue] : 0;
	if (queryIdentifier > 0) {
		if (![document isKindOfClass: [MADHeadlessDocument class]]) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage, @"query-scoped apply-connection requires a headless document.");
			return;
		}
		NSError *applyError = nil;
		if (![(MADHeadlessDocument *)document applyDatabaseConnection: connection
												  forQueryIdentifier: queryIdentifier
																error: &applyError]) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(applyError));
			return;
		}
	} else if ([document isKindOfClass: [MADHeadlessDocument class]]) {
		[(MADHeadlessDocument *)document applyDatabaseConnection: connection];
	} else {
		[document updateDatabaseWithConnection: connection];
	}

	MADCLIServeWriteResult(requestID, @{});
}

static MADCLIServeDocument *MADCLIServeLookup(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	if (![params[@"handle"] isKindOfClass: [NSNumber class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"handle must be a number.");
		return nil;
	}
	MADCLIServeDocument *entry = documents[params[@"handle"]];
	if (entry == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown handle %@.", params[@"handle"]]);
		return nil;
	}
	return entry;
}

static RptqQuery *MADCLIServeResolveLayoutQuery(id <MADDocumentDataProtocol> document, NSDictionary *params, NSError **outError);

static void MADCLIServeDescribe(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	BOOL explicitQuery = [params[@"query"] isKindOfClass: [NSNumber class]] && [params[@"query"] longLongValue] > 0;

	// `columns` come from the query's own fields (its ordered outputs for a composing
	// node, its per-table fields for a leaf), not a materialized result, so a scoped
	// describe works before any refresh.
	NSArray <NSDictionary *> *columns = nil;
	NSString *driver = nil;
	if (!explicitQuery) {
		columns = MADCLIServeColumns(document);
		driver = MADCLIServeDriverName(document);
	} else {
		columns = MADCLIServeColumnsForQuery(query);
		driver = [query isComposing] ? @"sqlite3"
			: (query.inDatabase != nil ? MADCLIServeTokenForDatabaseType((MADDatabaseType)query.inDatabase.databaseDriverTypeEnum) : @"");
	}

	NSArray <NSDictionary *> *tables = nil;
	if (!explicitQuery) {
		// No query: today's behavior, every database's schema concatenated.
		tables = MADCLIServeTables(document);
	} else if ([query isComposing]) {
		// A composing node's inputs are its children, not schema tables.
		tables = @[];
	} else {
		tables = MADCLIServeTablesForQuery(query);
	}

	MADCLIServeWriteResult(requestID, @{
		@"driver": driver,
		@"columns": columns,
		@"tables": tables,
	});
}

/// The query the report layout and data resolve against: the composed root when the
/// document has one, otherwise the document's single source query.
static RptqQuery *MADCLIServeReportQuery(id <MADDocumentDataProtocol> document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *root = model.rootQuery;
	return root ?: model.defaultDatabase.defaultQuery;
}

/// The generated SQL for a query, the way the Mac's Query workspace shows it: all
/// fields first (-SQLOnlyActiveFields:NO), falling back to the active-field select
/// when the query has no report elements to reference.  The composed root has no
/// single source statement (the refresh coordinator compiles it from its sources),
/// so it answers the empty string.  A leaf's dialect comes from the document's
/// database; for the SQLite sources this milestone authors, that is the source's own
/// dialect.
static NSString *MADCLIServeGeneratedSQLForQuery(id <MADDocumentDataProtocol> document, RptqQuery *query) {
	if (query == nil || [query isComposing]) return @"";
	MADQueryFull *compiler = [[MADQueryFull alloc] initWithQuery: query andQueryLimit: NSUIntegerMax];
	compiler.database = document.database;
	NSError *error = nil;
	NSString *generated = [compiler SQLOnlyActiveFields: NO managedObjectContext: document.storeContext error: &error];
	if (generated.length == 0) {
		generated = [compiler copySQLWithManagedObjectContext: document.storeContext error: &error];
	}
	return generated ?: @"";
}

static void MADCLIServeQuery(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	MADCLIServeWriteResult(requestID, @{ @"sql": MADCLIServeGeneratedSQLForQuery(document, MADCLIServeReportQuery(document)) });
}

/// A failed refresh, with the source that failed when the engine named one.  The
/// engine puts the leaf query's name, identifier and connection string in the
/// error's userInfo, which is what lets the WPF app prompt for that one source
/// instead of guessing.
static void MADCLIServeWriteRefreshError(id requestID, NSInteger code, NSError *error) {
	NSMutableDictionary *errorObject = [NSMutableDictionary dictionary];
	errorObject[@"code"] = @(code);
	errorObject[@"message"] = MADCLIDescriptionForError(error) ?: @"error";

	id name = error.userInfo[MADOperationRefreshSourceNameKey];
	id queryIdentifier = error.userInfo[MADOperationRefreshSourceQueryIdentifierKey];
	id connectionString = error.userInfo[MADOperationRefreshSourceConnectionStringKey];
	if (name != nil || queryIdentifier != nil || connectionString != nil) {
		NSMutableDictionary *source = [NSMutableDictionary dictionary];
		if ([name isKindOfClass: [NSString class]]) source[@"name"] = name;
		if ([queryIdentifier isKindOfClass: [NSNumber class]]) source[@"queryId"] = queryIdentifier;
		if ([connectionString isKindOfClass: [NSString class]]) source[@"connectionString"] = connectionString;
		errorObject[@"source"] = source;
	}

	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	response[@"id"] = requestID ?: [NSNull null];
	response[@"ok"] = @NO;
	response[@"error"] = errorObject;
	MADCLIServeWrite(requestID, response);
}

static void MADCLIServeRefresh(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;

	if ([params[@"rows"] isKindOfClass: [NSNumber class]]) {
		NSInteger rows = [params[@"rows"] integerValue];
		if (rows > 0) {
			document.mainQuery.limitResults = (NSUInteger)rows;
		}
	}

	MADCredential *credentials = nil;
	NSError *error = nil;
	if ([params[@"credentials"] isKindOfClass: [NSString class]]) {
		credentials = MADCLIServeCredential(params[@"credentials"], &error);
		if (credentials == nil && params[@"credentials"] != nil && [params[@"credentials"] length] > 0) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
			return;
		}
	}

	NSDictionary<NSNumber *, MADCredential *> *sourceCredentials = MADCLIServeSourceCredentials(params, &error);
	if (sourceCredentials == nil && error != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	NSDate *started = [NSDate date];
	if (![entry.document refreshWithCredentials: credentials sourceCredentials: sourceCredentials error: &error]) {
		MADCLIServeWriteRefreshError(requestID, MADCLIExitQueryFailed, error);
		return;
	}
	NSTimeInterval elapsed = -[started timeIntervalSinceNow];

	MADCLIServeWriteResult(requestID, @{
		@"rowCount": @(document.numberOfResults),
		@"elapsed": @(elapsed),
	});
}

/// A node's materialized rows: the selected query's output columns and rows, read
/// from its retained result (the root's published result, or a non-root node's from
/// the per-node map).  `refresh` stays whole-document; this is the query-scoped read.
static void MADCLIServeNodeResult(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	MADReportExportSource *source = [MADReportExportSource sourceWithDocument: document query: query error: &error];
	if (source == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitQueryFailed, MADCLIDescriptionForError(error));
		return;
	}

	NSMutableArray <NSDictionary *> *columns = [NSMutableArray arrayWithCapacity: source.columnKeys.count];
	for (NSString *key in source.columnKeys) {
		[columns addObject: @{
			@"key": key,
			@"name": [source columnName: key] ?: key,
			@"table": [source columnTable: key] ?: [NSNull null],
			@"type": [source columnType: key] ?: [NSNull null],
		}];
	}

	NSMutableArray <NSArray *> *rows = [NSMutableArray array];
	for (NSDictionary <NSString *, id> *row in [source rowEnumerator]) {
		NSMutableArray *values = [NSMutableArray arrayWithCapacity: source.columnKeys.count];
		for (NSString *key in source.columnKeys) {
			id value = row[key];
			[values addObject: value != nil ? value : [NSNull null]];
		}
		[rows addObject: values];
	}

	MADCLIServeWriteResult(requestID, @{
		@"query": @(query.identifier),
		@"name": query.name ?: @"",
		@"rowCount": @(source.numberOfRows),
		@"columns": columns,
		@"rows": rows,
	});
}

static void MADCLIServeExport(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSError *error = nil;
	NSString *format = MADCLIServeStringParam(params, @"format", &error);
	if (format == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	format = format.lowercaseString;

	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: format];
	if (exporterClass == Nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"--format %@ is not a format this build has; it has %@.",
				format, [[MADReportExporterRegistry registeredFormatNames] componentsJoinedByString: @", "]]);
		return;
	}
	if (![exporterClass isAvailable]) {
		MADCLIServeWriteError(requestID, MADCLIExitExportFailed,
			[NSString stringWithFormat: @"--format %@ is not available in this build: %@",
				format, [exporterClass unavailableReason] ?: @"no reason given"]);
		return;
	}

	// The exporter writes to a URL or to standard output.  Standard output is the
	// protocol channel here, so a run without a path writes to a private temporary
	// file and the bytes are returned in `data` -- still the exporter's own bytes,
	// identical to `mad export --format <format>`.
	NSString *path = [params[@"path"] isKindOfClass: [NSString class]] ? params[@"path"] : nil;
	NSURL *outURL = nil;
	NSURL *temporaryURL = nil;
	BOOL capture = path.length == 0;
	if (capture) {
		temporaryURL = [NSURL fileURLWithPath:
			[NSTemporaryDirectory() stringByAppendingPathComponent:
				[@"mad-serve-" stringByAppendingString: NSUUID.UUID.UUIDString]]];
		outURL = temporaryURL;
	} else {
		outURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(path)];
		NSError *directoryError = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtURL: [outURL URLByDeletingLastPathComponent]
									  withIntermediateDirectories: YES
														attributes: nil
															 error: &directoryError]) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage,
				[NSString stringWithFormat: @"export: cannot create %@: %@",
					[outURL URLByDeletingLastPathComponent].path, directoryError.localizedDescription]);
			return;
		}
	}

	BOOL deterministic = [params[@"deterministic"] isKindOfClass: [NSNumber class]] && [params[@"deterministic"] boolValue];
	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	MADReportExportOptions exportOptions = deterministic ? MADReportExportOptionsDeterministic : MADReportExportOptionsNone;
	BOOL rootNode = query.rootOfDocument != nil || query == MADCLIServeReportQuery(document);
	BOOL ok = NO;
	if ([exporter respondsToSelector: @selector(exportDocument:query:toURL:options:error:)]) {
		ok = [exporter exportDocument: document query: query toURL: outURL options: exportOptions error: &error];
	} else if (!rootNode) {
		// A format that has not learned to render a specific node must not silently
		// render the root for a non-root query.
		if (temporaryURL) [[NSFileManager defaultManager] removeItemAtURL: temporaryURL error: NULL];
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"--format %@ cannot export a specific node.", format]);
		return;
	} else {
		ok = [exporter exportDocument: document toURL: outURL options: exportOptions error: &error];
	}
	if (!ok) {
		if (temporaryURL) [[NSFileManager defaultManager] removeItemAtURL: temporaryURL error: NULL];
		MADCLIServeWriteError(requestID, MADCLIExitExportFailed, MADCLIDescriptionForError(error));
		return;
	}

	if (capture) {
		NSData *bytes = [NSData dataWithContentsOfURL: temporaryURL];
		NSString *data = [[NSString alloc] initWithData: bytes encoding: NSUTF8StringEncoding];
		[[NSFileManager defaultManager] removeItemAtURL: temporaryURL error: NULL];
		MADCLIServeWriteResult(requestID, @{ @"format": format, @"data": data ?: @"" });
	} else {
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
		MADCLIServeWriteResult(requestID, @{
			@"format": format,
			@"path": path,
			@"bytes": attributes[NSFileSize] ?: @0,
		});
	}
}

static void MADCLIServeWriteCopy(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSError *error = nil;
	NSString *outPath = MADCLIServeStringParam(params, @"out", &error);
	if (outPath == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	// Write the live session document so an in-memory change (apply-connection) is
	// persisted.  On Apple the session document is a UIDocument-backed MADocument, so
	// fall back to re-opening the source URL the way `mad write` does.
	id <MADDocumentDataProtocol> protocolDocument = entry.document.document;
	MADHeadlessDocument *document = [protocolDocument isKindOfClass: [MADHeadlessDocument class]]
		? (MADHeadlessDocument *)protocolDocument
		: [MADHeadlessDocument documentWithContentsOfURL: entry.sourceURL error: &error];
	if (document == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}

	NSURL *outURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(outPath)];
	NSError *directoryError = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtURL: [outURL URLByDeletingLastPathComponent]
								  withIntermediateDirectories: YES
													attributes: nil
														 error: &directoryError]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"write: cannot create %@: %@",
				[outURL URLByDeletingLastPathComponent].path, directoryError.localizedDescription]);
		return;
	}

	BOOL reproducible = [params[@"reproducible"] isKindOfClass: [NSNumber class]] && [params[@"reproducible"] boolValue];
	if (![document writeToURL: outURL reproducible: reproducible error: &error]) {
		MADCLIServeWriteError(requestID, MADCLIExitExportFailed, MADCLIDescriptionForError(error));
		return;
	}

	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
	MADCLIServeWriteResult(requestID, @{ @"path": outPath, @"bytes": attributes[NSFileSize] ?: @0 });
}

#pragma mark - Query model (Phase 6b)

/// The document's main RptqQuery, read live from the store each call.  Reading through
/// -newDocumentReadFromManagedObjectContext: (rather than the cached activeDocumentModel)
/// means every mutation below is visible to the next read with no explicit invalidation --
/// the same way -copySQLWithManagedObjectContext: already re-reads the query.
static RptqQuery *MADCLIServeMainQuery(id <MADDocumentDataProtocol> document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	return model.defaultDatabase.defaultQuery;
}

/// The query a request targets: the `query` parameter (an identifier) when present,
/// else the document's default query.  A `query` that does not resolve answers nil
/// and fills `outError` with an actionable message; the document is untouched.
static RptqQuery *MADCLIServeResolveQuery(id <MADDocumentDataProtocol> document,
										  NSDictionary *params,
										  NSError **outError) {
	int64_t queryID = [params[@"query"] isKindOfClass: [NSNumber class]] ? [params[@"query"] longLongValue] : 0;
	if (queryID > 0) {
		RptqQuery *query = (RptqQuery *)[document.storeContext objectForEntity: NSStringFromClass([RptqQuery class])
																	 identifier: queryID];
		if (query == nil && outError != NULL) {
			*outError = MADCLIServeUsageError([NSString stringWithFormat: @"no query %lld in this document.", queryID]);
		}
		return query;
	}
	return MADCLIServeMainQuery(document);
}

/// The query a layout/describe/result/export request targets: the `query` parameter
/// when present, else the report query (the composed root, or the single source).  An
/// unknown `query` answers nil and fills `outError`; the document is untouched.
static RptqQuery *MADCLIServeResolveLayoutQuery(id <MADDocumentDataProtocol> document,
												NSDictionary *params,
												NSError **outError) {
	int64_t queryID = [params[@"query"] isKindOfClass: [NSNumber class]] ? [params[@"query"] longLongValue] : 0;
	if (queryID > 0) {
		RptqQuery *query = (RptqQuery *)[document.storeContext objectForEntity: NSStringFromClass([RptqQuery class])
																	 identifier: queryID];
		if (query == nil && outError != NULL) {
			*outError = MADCLIServeUsageError([NSString stringWithFormat: @"no query %lld in this document.", queryID]);
		}
		return query;
	}
	return MADCLIServeReportQuery(document);
}

/// The document cast to the query-editing protocol (group/delete helpers) both the Mac and
/// headless documents conform to; nil when the document cannot edit its query.
static id <MADSQLQueryDocument> MADCLIServeQueryDocument(id <MADDocumentDataProtocol> document) {
	if ([document conformsToProtocol: @protocol(MADSQLQueryDocument)]) {
		return (id <MADSQLQueryDocument>)document;
	}
	return nil;
}

/// The full query model as JSON -- tables/fields/links/predicates/groups with their store
/// identifiers, the generated SQL, the entered SQL, and the driver token.  This is what the
/// WPF Query workspace round-trips: every mutation method below answers this same shape so
/// the client replaces its snapshot atomically.
static NSDictionary *MADCLIServeQueryModelDict(id <MADDocumentDataProtocol> document, RptqQuery *query) {
	RptqStoreContext *context = document.storeContext;

	NSString *driver = @"";
	if ([query isComposing]) {
		// A composing node (root or a non-root composer) compiles against the local
		// SQLite composer.
		driver = @"sqlite3";
	} else if (query.inDatabase != nil && query.inDatabase.databaseDriverTypeEnum != MADDatabaseTypeNotSet) {
		driver = MADCLIServeTokenForDatabaseType((MADDatabaseType)query.inDatabase.databaseDriverTypeEnum);
	}

	NSString *sql = MADCLIServeGeneratedSQLForQuery(document, query);

	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES
															  selector: @selector(localizedCaseInsensitiveCompare:)];
	NSSortDescriptor *byID = [NSSortDescriptor sortDescriptorWithKey: @"id" ascending: YES];

	NSMutableArray <NSDictionary *> *tables = [NSMutableArray array];
	for (RptqQueryTable *table in query.hasQueryTables) {
		NSMutableArray <NSDictionary *> *fields = [NSMutableArray array];
		for (RptqQueryField *field in table.hasQueryFields) {
			[fields addObject: @{
				@"id": @(field.identifier),
				@"name": field.databaseSchemaField.name ?: @"",
				@"type": MADCLIServeTypeName(field.databaseSchemaField.dataType),
				@"outputKey": (field.outputKey.length > 0 ? field.outputKey : [NSNull null]),
				@"outputIndex": @(field.outputIndex),
			}];
		}
		[fields sortUsingDescriptors: @[byName]];
		BOOL isUpstream = (table.upstreamQuery != nil);
		[tables addObject: @{
			@"id": @(table.identifier),
			@"name": isUpstream ? (table.upstreamQuery.name ?: @"") : (table.databaseSchemaTable.name ?: @""),
			@"alias": table.alias ?: @"",
			@"dropIndex": @(table.dropIndex),
			@"upstreamQuery": @(isUpstream ? table.upstreamQuery.identifier : 0),
			@"fields": fields,
		}];
	}
	[tables sortUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"dropIndex" ascending: YES], byName]];

	NSMutableArray <NSDictionary *> *links = [NSMutableArray array];
	for (RptqQueryLinks *link in query.hasQueryLinks) {
		[links addObject: @{
			@"id": @(link.identifier),
			@"type": @(link.type),
			@"leftField": @(link.hasLeftField ? link.hasLeftField.identifier : 0),
			@"rightField": @(link.hasRightField ? link.hasRightField.identifier : 0),
		}];
	}
	[links sortUsingDescriptors: @[byID]];

	NSMutableArray <NSDictionary *> *predicates = [NSMutableArray array];
	for (RptqQueryPredicate *predicate in query.hasQueryPredicate) {
		[predicates addObject: @{
			@"id": @(predicate.identifier),
			@"operator": @(predicate.comparson),
			@"leftField": @(predicate.hasLeftField ? predicate.hasLeftField.identifier : 0),
			@"rightField": @(predicate.hasRightField ? predicate.hasRightField.identifier : 0),
			@"leftValue": (predicate.leftFieldID != nil ? predicate.leftFieldID : [NSNull null]),
			@"rightValue": (predicate.rightFieldID != nil ? predicate.rightFieldID : [NSNull null]),
		}];
	}
	[predicates sortUsingDescriptors: @[byID]];

	NSMutableArray <NSDictionary *> *groups = [NSMutableArray array];
	for (RptqQueryGroup *group in query.hasQueryGroups) {
		[groups addObject: @{
			@"id": @(group.identifier),
			@"field": @(group.hasField ? group.hasField.identifier : 0),
			@"sort": @(group.sort),
		}];
	}
	[groups sortUsingDescriptors: @[byID]];

	return @{
		@"queryId": @(query.identifier),
		@"isRoot": @(query.rootOfDocument != nil ? YES : NO),
		@"isComposing": @([query isComposing]),
		@"driver": driver,
		@"sql": sql,
		@"sqlSourceText": query.sqlSourceText ?: @"",
		@"tables": tables,
		@"links": links,
		@"predicates": predicates,
		@"groups": groups,
	};
}

static void MADCLIServeQueryModel(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeAddTable(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSString *name = MADCLIServeOptionalString(params, @"table");
	if (name == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"table must be a non-empty string.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqDatabase *database = query.inDatabase;

	RptqDatabaseSchemaTable *schemaTable = nil;
	for (RptqDatabaseSchemaTable *candidate in database.hasTables) {
		if ([candidate.name isEqualToString: name]) {
			schemaTable = candidate;
			break;
		}
	}
	if (schemaTable == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"no schema table named '%@'.", name]);
		return;
	}

	// Mirrors MADMacQueryViewController -addSchemaTableToQuery: a query table plus one query
	// field per schema field.
	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
																	   query: query
													 forManagedObjectContext: context];
	NSMutableSet <RptqQueryField *> *queryFields = [NSMutableSet setWithCapacity: schemaTable.hasFields.count];
	for (RptqDatabaseSchemaField *schemaField in schemaTable.hasFields) {
		RptqQueryField *field = [RptqQueryField newQueryField: context];
		field.inQueryTable = queryTable;
		field.databaseSchemaField = schemaField;
		[queryFields addObject: field];
	}
	queryTable.hasQueryFields = queryFields;
	[query addHasQueryTablesObject: queryTable];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeRemoveTable(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	if (![params[@"table"] isKindOfClass: [NSNumber class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"table must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	id <MADSQLQueryDocument> qdoc = MADCLIServeQueryDocument(document);
	if (qdoc == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"the document cannot edit its query.");
		return;
	}
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	int64_t tableID = [params[@"table"] longLongValue];
	RptqQueryTable *table = (RptqQueryTable *)[context objectForEntity: NSStringFromClass([RptqQueryTable class]) identifier: tableID];
	if (table == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown query table %lld.", tableID]);
		return;
	}

	// Mirrors MADMacQueryViewController -removeQueryTable: designer-element cleanup, then the
	// groups/links/predicates/fields that touch the table, then the table itself.
	[qdoc deleteDatafieldsRelatedToTable: tableID inContent: context];
	[qdoc deleteAggregateFieldRelatedToTable: tableID inContent: context];
	for (RptqQueryGroup *group in [query.hasQueryGroups allObjects]) {
		if (group.hasField.inQueryTable.identifier == tableID) {
			[qdoc removeGroupWitObjectID: group.identifier fromManagedObjectContext: context];
		}
	}
	for (RptqQueryLinks *link in [query.hasQueryLinks allObjects]) {
		if ([link isConnectedToTable: table]) {
			[query removeHasQueryLinksObject: link];
			[context deleteObject: link error: NULL];
		}
	}
	for (RptqQueryPredicate *predicate in [query.hasQueryPredicate allObjects]) {
		if (predicate.hasLeftField.inQueryTable.identifier == tableID ||
			predicate.hasRightField.inQueryTable.identifier == tableID) {
			[query removeHasQueryPredicateObject: predicate];
			[context deleteObject: predicate error: NULL];
		}
	}
	for (RptqQueryField *field in [table.hasQueryFields allObjects]) {
		[context deleteObject: field error: NULL];
	}
	[query removeHasQueryTablesObject: table];
	[context deleteObject: table error: NULL];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeAddLink(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t leftID = [params[@"leftField"] isKindOfClass: [NSNumber class]] ? [params[@"leftField"] longLongValue] : 0;
	int64_t rightID = [params[@"rightField"] isKindOfClass: [NSNumber class]] ? [params[@"rightField"] longLongValue] : 0;
	if (leftID == 0 || rightID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"leftField and rightField must be numbers.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryField *left = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: leftID];
	RptqQueryField *right = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: rightID];
	if (left == nil || right == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"unknown query field.");
		return;
	}
	if (left.inQueryTable.identifier == right.inQueryTable.identifier) {
		MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query)); // no-op, like the Mac
		return;
	}

	for (RptqQueryLinks *existing in query.hasQueryLinks) {
		if ((existing.hasLeftField.identifier == leftID && existing.hasRightField.identifier == rightID) ||
			(existing.hasLeftField.identifier == rightID && existing.hasRightField.identifier == leftID)) {
			MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query)); // already linked
			return;
		}
	}

	RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField: left
														   rightField: right
															 joinType: MADLinkTypeLeftOuterJoin
												 managedObjectContext: context];
	[query addHasQueryLinksObject: link];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeSetLinkType(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t linkID = [params[@"link"] isKindOfClass: [NSNumber class]] ? [params[@"link"] longLongValue] : 0;
	if (linkID == 0 || ![params[@"type"] isKindOfClass: [NSNumber class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"link and type must be numbers.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryLinks *link = (RptqQueryLinks *)[document.storeContext objectForEntity: NSStringFromClass([RptqQueryLinks class]) identifier: linkID];
	if (link == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown query link %lld.", linkID]);
		return;
	}
	link.type = (int16_t)[params[@"type"] integerValue];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeSwapLink(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t linkID = [params[@"link"] isKindOfClass: [NSNumber class]] ? [params[@"link"] longLongValue] : 0;
	if (linkID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"link must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryLinks *link = (RptqQueryLinks *)[document.storeContext objectForEntity: NSStringFromClass([RptqQueryLinks class]) identifier: linkID];
	if (link == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown query link %lld.", linkID]);
		return;
	}

	RptqQueryField *oldLeft = link.hasLeftField;
	RptqQueryField *oldRight = link.hasRightField;
	if (oldLeft != nil && oldRight != nil) {
		link.hasLeftField = oldRight;
		link.hasRightField = oldLeft;
		link.tableLeftID = oldRight.inQueryTable.alias.copy;
		link.fieldLeftID = oldRight.databaseSchemaField.name.copy;
		link.tableRightID = oldLeft.inQueryTable.alias.copy;
		link.fieldRightID = oldLeft.databaseSchemaField.name.copy;
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeDeleteLink(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t linkID = [params[@"link"] isKindOfClass: [NSNumber class]] ? [params[@"link"] longLongValue] : 0;
	if (linkID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"link must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryLinks *link = (RptqQueryLinks *)[context objectForEntity: NSStringFromClass([RptqQueryLinks class]) identifier: linkID];
	if (link != nil) {
		[query removeHasQueryLinksObject: link];
		[context deleteObject: link error: NULL];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeAddPredicate(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t leftID = [params[@"leftField"] isKindOfClass: [NSNumber class]] ? [params[@"leftField"] longLongValue] : 0;
	NSString *value = [params[@"value"] isKindOfClass: [NSString class]] ? params[@"value"] : nil;
	if (leftID == 0 || value.length == 0 || ![params[@"operator"] isKindOfClass: [NSNumber class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"leftField, operator and a non-empty value are required.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: leftID
																			comparsonOperator: (MADPredicateOperator)[params[@"operator"] integerValue]
																				andRightValue: value
																  forManagedObjectContext: document.storeContext
																						error: &error];
	if (predicate == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	[query addHasQueryPredicateObject: predicate];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeRemovePredicate(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t predicateID = [params[@"predicate"] isKindOfClass: [NSNumber class]] ? [params[@"predicate"] longLongValue] : 0;
	if (predicateID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"predicate must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context objectForEntity: NSStringFromClass([RptqQueryPredicate class]) identifier: predicateID];
	if (predicate != nil) {
		[query removeHasQueryPredicateObject: predicate];
		[context deleteObject: predicate error: NULL];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeAddGroup(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t fieldID = [params[@"field"] isKindOfClass: [NSNumber class]] ? [params[@"field"] longLongValue] : 0;
	if (fieldID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"field must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	MADSortOrder sort = ([params[@"sort"] isKindOfClass: [NSNumber class]] && [params[@"sort"] integerValue] == 1)
		? MADSortOrderDecending : MADSortOrderAccending;

	// Mirrors MADHeadlessDocument -addQueryGroupWithQueryField:andSortOrder:, but the
	// group is added to the selected query rather than the document's default one.
	RptqQueryField *groupField = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: fieldID];
	if (groupField == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"unknown query field.");
		return;
	}
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder: sort andManagedObjectContext: context];
	group.hasField = groupField;
	RptqDocumentSection *header = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader forManagedObjectContext: context];
	RptqDocumentSectionRows *headerRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: context];
	headerRow.inSection = header;
	header.hasRows = [NSMutableOrderedSet orderedSetWithObject: headerRow];
	[group addHasSectionObject: header];
	RptqDocumentSection *footer = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter forManagedObjectContext: context];
	RptqDocumentSectionRows *footerRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: context];
	footerRow.inSection = footer;
	footer.hasRows = [NSMutableOrderedSet orderedSetWithObject: footerRow];
	[group addHasSectionObject: footer];
	[query addHasQueryGroupsObject: group];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

static void MADCLIServeRemoveGroup(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t groupID = [params[@"group"] isKindOfClass: [NSNumber class]] ? [params[@"group"] longLongValue] : 0;
	if (groupID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"group must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	id <MADSQLQueryDocument> qdoc = MADCLIServeQueryDocument(document);
	if (qdoc == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"the document cannot edit its query.");
		return;
	}
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	[qdoc removeGroupWitObjectID: groupID fromManagedObjectContext: document.storeContext];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, query));
}

#pragma mark - Composition authoring (Phase 6g)

/// The source connection a query's persisted credential row describes, in the same
/// wire shape `connection` uses, plus `requiresCredentials` and the stored username
/// hint.  Answers nil for a query with no source database (a composing node), so a
/// client prompts only for real leaves.
static NSDictionary *MADCLIServeSourceConnectionDict(id <MADDocumentDataProtocol> document, RptqQuery *query) {
	RptqDatabase *database = query.inDatabase;
	RptqDatabaseCredentals *credRow = database.ownedByUser;
	if (credRow == nil) return nil;

	NSURL *documentURL = [document respondsToSelector: @selector(fileURL)] ? [(id)document fileURL] : nil;
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: credRow documentURL: documentURL];
	if (connection == nil) return nil;

	MADDatabaseType type = connection.databaseType;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"driver"] = MADCLIServeTokenForDatabaseType(type);
	result[@"connectionString"] = connection.connectionString ?: @"";
	result[@"requiresCredentials"] = @([connection requiresCredentials]);
	if (credRow.domain.length > 0) result[@"usernameHint"] = credRow.domain;

	if (type == MADDatabaseTypeSqlite3) {
		if ([connection conformsToProtocol: @protocol(MADDatabaseConnectionsPropertiesURL)]) {
			NSURL *databaseURL = ((id <MADDatabaseConnectionsPropertiesURL>)connection).databaseUrl;
			result[@"file"] = databaseURL.path ?: @"";
		}
	} else if ([connection conformsToProtocol: @protocol(MADConnectionsPropertiesProtocol)]) {
		id <MADConnectionsPropertiesProtocol> serverConnection = (id <MADConnectionsPropertiesProtocol>)connection;
		result[@"host"] = serverConnection.host ?: @"";
		result[@"port"] = @(serverConnection.port);
		result[@"database"] = serverConnection.database ?: @"";
		if (type == MADDatabaseTypeTDS) {
			result[@"server"] = serverConnection.server ?: @"";
		}
	}
	return result;
}

/// One query in document-info: its identity, whether it is the root or a composer,
/// and, for a leaf, the source connection a client may need to configure or prompt
/// for.  A Standard Report's single query carries its connection here too.
static NSDictionary *MADCLIServeDocumentInfoQuery(id <MADDocumentDataProtocol> document,
												  RptqQuery *query,
												  BOOL isRoot) {
	NSMutableDictionary *entry = [NSMutableDictionary dictionary];
	entry[@"id"] = @(query.identifier);
	entry[@"name"] = query.name ?: @"";
	entry[@"isRoot"] = @(isRoot);
	entry[@"isComposing"] = query.hasQueryTables.anyObject.upstreamQuery != nil ? @YES : @NO;
	NSDictionary *connection = MADCLIServeSourceConnectionDict(document, query);
	if (connection != nil) entry[@"connection"] = connection;
	return entry;
}

/// The document's type and its queries, in authoring order (the composed root first,
/// then each source).  A single-query document reports `composed == false` and one
/// query; an empty document reports no queries.
static NSDictionary *MADCLIServeDocumentInfoDict(id <MADDocumentDataProtocol> document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *root = model.rootQuery;
	NSMutableArray <NSDictionary *> *queries = [NSMutableArray array];
	if (root != nil) {
		[queries addObject: MADCLIServeDocumentInfoQuery(document, root, YES)];
	}
	for (RptqDatabase *database in model.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if (query == root) continue;
			[queries addObject: MADCLIServeDocumentInfoQuery(document, query, NO)];
		}
	}
	if (queries.count == 0) {
		RptqQuery *single = model.defaultDatabase.defaultQuery;
		if (single != nil) [queries addObject: MADCLIServeDocumentInfoQuery(document, single, NO)];
	}
	return @{
		@"composed": (root != nil ? @YES : @NO),
		@"rootQuery": @(root != nil ? root.identifier : 0),
		@"queries": queries,
	};
}

static void MADCLIServeDocumentInfo(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	MADCLIServeWriteResult(requestID, MADCLIServeDocumentInfoDict(entry.document.document));
}

static void MADCLIServeCreateEmpty(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	NSError *error = nil;
	NSString *path = MADCLIServeStringParam(params, @"path", &error);
	if (path == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	NSURL *url = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(path)];
	NSError *directoryError = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtURL: [url URLByDeletingLastPathComponent]
									  withIntermediateDirectories: YES
														attributes: nil
															 error: &directoryError]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"create: cannot create %@: %@",
				[url URLByDeletingLastPathComponent].path, directoryError.localizedDescription]);
		return;
	}
	MADHeadlessDocument *document = [MADHeadlessDocument createEmptyDocumentAtURL: url error: &error];
	if (document == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}
	NSInteger handle = 0;
	for (NSNumber *candidate in documents.allKeys) {
		if (candidate.integerValue >= handle) handle = candidate.integerValue + 1;
	}
	MADCLIDocument *cliDocument = [[MADCLIDocument alloc] initWithDocument: document];
	MADCLIServeDocument *entry = [[MADCLIServeDocument alloc] init];
	entry.document = cliDocument;
	entry.sourceURL = url;
	documents[@(handle)] = entry;
	MADCLIServeWriteResult(requestID, @{
		@"handle": @(handle),
		@"filename": url.lastPathComponent ?: @"",
		@"driver": MADCLIServeDriverName(document),
	});
}

static void MADCLIServeAddRoot(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	NSString *name = MADCLIServeOptionalString(params, @"name");
	if (name == nil) name = @"root";

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	if (model.rootQuery != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"this document already has a composed root.");
		return;
	}
	RptqQuery *root = (RptqQuery *)[context insertObjectForEntity: NSStringFromClass([RptqQuery class]) identifier: 0];
	root.name = name;
	root.inDatabase = model.hasDatabaseSchemas.anyObject; // a placeholder so ordinary accessors resolve
	model.rootQuery = root;

	MADCLIServeWriteResult(requestID, MADCLIServeDocumentInfoDict(document));
}

static void MADCLIServeAddSource(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	NSString *name = MADCLIServeOptionalString(params, @"name");
	if (name == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"name must be a non-empty string.");
		return;
	}

	NSError *error = nil;
	MADCredential *credentials = nil;
	MADDatabaseConnection *connection = MADCLIServeBuildConnection(params, &credentials, &error);
	if (connection == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];
	id dbHandle = [database connectWithConnection: connection credentals: credentials connectionError: &error];
	if (dbHandle == nil || error != nil) {
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}
	NSArray <MADDatabaseTable *> *tables = [database getTablesFromConnection: dbHandle error: &error];
	if (tables == nil || error != nil) {
		[database closeConnection: dbHandle];
		MADCLIServeWriteError(requestID, MADCLIExitDatabaseUnreachable, MADCLIDescriptionForError(error));
		return;
	}
	NSMutableDictionary <NSString *, NSArray <MADDatabaseField *> *> *fieldsByTable = [NSMutableDictionary dictionary];
	for (MADDatabaseTable *table in tables) {
		if (table.name.length == 0) continue;
		NSArray <MADDatabaseField *> *fields = [database fieldsForTable: table.name connection: dbHandle error: NULL];
		if (fields != nil) fieldsByTable[table.name] = fields;
	}
	[database closeConnection: dbHandle];

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	NSSet *before = [model.hasDatabaseSchemas copy];
	[model storeDatabaseConnectionDefination: database forManagedObjectContext: context];

	RptqDatabase *newDatabase = nil;
	for (RptqDatabase *candidate in model.hasDatabaseSchemas) {
		if (![before containsObject: candidate]) { newDatabase = candidate; break; }
	}
	if (newDatabase == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"could not register the new source database.");
		return;
	}
	RptqQuery *newQuery = newDatabase.hasQueries.anyObject;
	newQuery.name = name;
	// A new source query owns its five structural sections from the start, so the
	// designer can author it immediately (per-node layout, store revision 4).
	[RptqDocumentSection createStructuralSectionsForQuery: newQuery managedObjectContext: context];

	for (MADDatabaseTable *table in tables) {
		NSArray <MADDatabaseField *> *fields = fieldsByTable[table.name];
		if (fields.count == 0) continue;
		RptqDatabaseSchemaTable *schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext: context andTable: table];
		[newDatabase addHasTablesObject: schemaTable];
		NSMutableArray <RptqDatabaseSchemaField *> *schemaFields = [NSMutableArray arrayWithCapacity: fields.count];
		for (MADDatabaseField *field in fields) {
			[schemaFields addObject: [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext: context andField: field]];
		}
		schemaTable.hasFields = [NSOrderedSet orderedSetWithArray: schemaFields];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeDocumentInfoDict(document));
}

static void MADCLIServeAddUpstream(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	int64_t childID = [params[@"query"] isKindOfClass: [NSNumber class]] ? [params[@"query"] longLongValue] : 0;
	if (childID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"query must be the child query's id.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: context];
	RptqQuery *root = model.rootQuery;
	if (root == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"this document has no composed root.");
		return;
	}
	RptqQuery *child = (RptqQuery *)[context objectForEntity: NSStringFromClass([RptqQuery class]) identifier: childID];
	if (child == nil || child == root) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"no child query %lld.", childID]);
		return;
	}
	for (RptqQueryTable *existing in root.hasQueryTables) {
		if (existing.upstreamQuery == child) {
			MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, root)); // already an input
			return;
		}
	}

	RptqQueryTable *table = (RptqQueryTable *)[context insertObjectForEntity: NSStringFromClass([RptqQueryTable class]) identifier: 0];
	table.inQuery = root;
	table.upstreamQuery = child;
	NSMutableSet <RptqQueryField *> *fields = [NSMutableSet set];
	for (RptqQueryTable *sourceTable in child.hasQueryTables) {
		for (RptqQueryField *sourceField in sourceTable.hasQueryFields) {
			if (sourceField.databaseSchemaField == nil) continue;
			RptqQueryField *qf = [RptqQueryField newQueryField: context];
			qf.inQueryTable = table;
			qf.databaseSchemaField = sourceField.databaseSchemaField;
			[fields addObject: qf];
		}
	}
	table.hasQueryFields = fields;
	[root addHasQueryTablesObject: table];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, root));
}

static void MADCLIServeImportChild(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	NSString *path = MADCLIServeOptionalString(params, @"path");
	if (path == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"path must be a non-empty string.");
		return;
	}
	NSString *name = MADCLIServeOptionalString(params, @"name");

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSURL *sourceURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(path)];
	NSError *error = nil;
	MADHeadlessDocument *source = [MADHeadlessDocument documentWithContentsOfURL: sourceURL error: &error];
	if (source == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}
	RptqStoreContext *sourceContext = source.storeContext;
	if (sourceContext == nil || ![sourceContext loadAllWithError: &error]) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}
	RptqQuery *imported = [document.storeContext importQueryGraphFromContext: sourceContext
														relativePathBaseURL: sourceURL
																	   error: &error];
	if (imported == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitBadDocument, MADCLIDescriptionForError(error));
		return;
	}
	if (name.length > 0) imported.name = name;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *root = model.rootQuery;
	if (root == nil) {
		root = (RptqQuery *)[document.storeContext insertObjectForEntity: NSStringFromClass([RptqQuery class]) identifier: 0];
		root.name = @"root";
		root.inDatabase = model.hasDatabaseSchemas.anyObject;
		model.rootQuery = root;
	}
	RptqQueryTable *table = [model addChildQuery: imported error: &error];
	if (table == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	MADCLIServeWriteResult(requestID, MADCLIServeDocumentInfoDict(document));
}

static void MADCLIServeConvert(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	NSString *childName = MADCLIServeOptionalString(params, @"childName");
	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSError *error = nil;
	RptqQuery *root = [model convertToCompositionWithChildName: childName error: &error];
	if (root == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	MADCLIServeWriteResult(requestID, MADCLIServeDocumentInfoDict(document));
}

static void MADCLIServeSetRootOutputs(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	RptqQuery *root = model.rootQuery;
	if (root == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"this document has no composed root.");
		return;
	}
	NSArray *outputs = [params[@"outputs"] isKindOfClass: [NSArray class]] ? params[@"outputs"] : nil;
	if (outputs == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"outputs must be an array.");
		return;
	}

	for (RptqQueryTable *table in root.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			field.outputKey = nil;
			field.outputIndex = 0;
		}
	}

	int64_t index = 0;
	for (NSDictionary *item in outputs) {
		if (![item isKindOfClass: [NSDictionary class]]) continue;
		int64_t fieldID = [item[@"field"] isKindOfClass: [NSNumber class]] ? [item[@"field"] longLongValue] : 0;
		NSString *key = [item[@"key"] isKindOfClass: [NSString class]] ? item[@"key"] : nil;
		if (fieldID == 0 || key.length == 0) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage, @"each output needs a field and a key.");
			return;
		}
		RptqQueryField *field = (RptqQueryField *)[document.storeContext objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: fieldID];
		if (field == nil) {
			MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown query field %lld.", fieldID]);
			return;
		}
		field.outputKey = key;
		field.outputIndex = index++;
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document, root));
}

#pragma mark - SQL entry (Phase 6b)

/// Parses `sql` and resolves it against the document's schema (and, when `apply`, runs the
/// compiler).  Returns the plan, or nil with `outError` -- the same MADSQLParser →
/// MADSQLStatementResolver → MADSQLQueryCompiler path the Mac's SQL editor takes.
static MADSQLQueryPlan *MADCLIServeCompileSQL(id <MADDocumentDataProtocol> document, RptqQuery *query, NSString *sql, BOOL apply, NSError **outError) {
	if ([query isComposing]) {
		if (outError) *outError = MADCLIServeUsageError(@"SQL editing is not supported for a composed node.");
		return nil;
	}
	RptqStoreContext *context = document.storeContext;
	RptqDatabase *database = query.inDatabase;
	if (database == nil) {
		if (outError) *outError = MADCLIServeUsageError(@"this query has no source database to compile SQL against.");
		return nil;
	}

	NSMutableDictionary <NSString *, NSArray <NSString *> *> *schema = [NSMutableDictionary dictionary];
	for (RptqDatabaseSchemaTable *table in database.hasTables) {
		if (table.name.length == 0) continue;
		NSMutableArray <NSString *> *columns = [NSMutableArray array];
		for (RptqDatabaseSchemaField *field in table.hasFields) {
			if (field.name.length > 0) [columns addObject: field.name];
		}
		schema[table.name] = columns;
	}

	NSError *error = nil;
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL: sql
									identifierQuoteCharacters: [MADDatabase identifierQuoteCharacters]
													   schema: schema];
	MADSQLStatement *statement = [parser parseStatement: &error];
	if (statement == nil) {
		if (outError) *outError = error;
		return nil;
	}

	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement: statement database: database];
	MADSQLQueryPlan *plan = [resolver resolveWithError: &error];
	if (plan == nil) {
		if (outError) *outError = error;
		return nil;
	}

	if (apply) {
		id <MADSQLQueryDocument> qdoc = MADCLIServeQueryDocument(document);
		if (qdoc == nil) {
			if (outError) *outError = MADCLIServeUsageError(@"the document cannot edit its query.");
			return nil;
		}
		MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan: plan
																		  document: qdoc
																			 query: query
																		   context: context];
		if (![compiler applyWithError: &error]) {
			if (outError) *outError = error;
			return nil;
		}
	}

	return plan;
}

static NSDictionary *MADCLIServeCompileResult(MADSQLQueryPlan *plan) {
	return @{
		@"tables": @(plan.tables.count),
		@"links": @(plan.links.count),
		@"predicates": @(plan.predicates.count),
		@"groups": @(plan.groups.count),
	};
}

static void MADCLIServeValidateSQL(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSError *error = nil;
	NSString *sql = MADCLIServeStringParam(params, @"sql", &error);
	if (sql == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *resolveError = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &resolveError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(resolveError));
		return;
	}

	NSError *compileError = nil;
	MADSQLQueryPlan *plan = MADCLIServeCompileSQL(document, query, sql, NO, &compileError);
	if (plan == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitQueryFailed, MADCLIDescriptionForError(compileError));
		return;
	}
	MADCLIServeWriteResult(requestID, MADCLIServeCompileResult(plan));
}

static void MADCLIServeApplySQL(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSError *error = nil;
	NSString *sql = MADCLIServeStringParam(params, @"sql", &error);
	if (sql == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *resolveError = nil;
	RptqQuery *query = MADCLIServeResolveQuery(document, params, &resolveError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(resolveError));
		return;
	}

	NSError *compileError = nil;
	MADSQLQueryPlan *plan = MADCLIServeCompileSQL(document, query, sql, YES, &compileError);
	if (plan == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitQueryFailed, MADCLIDescriptionForError(compileError));
		return;
	}
	MADCLIServeWriteResult(requestID, MADCLIServeCompileResult(plan));
}

#pragma mark - Report layout (Phase 6c)

/// The report's sections in the order the designer draws them — the same order
/// MADMacDocument -orderedSections yields: Report Header, Page Header, Group Headers,
/// Detail, Group Footers, Page Footer, Report Footer.
static NSArray <RptqDocumentSection *> *MADCLIServeOrderedSections(id <MADDocumentDataProtocol> document, RptqQuery *query) {
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	if (query == nil) query = doc.rootQuery ?: doc.defaultDatabase.defaultQuery;
	return [query orderedLayoutSectionsForDocument: doc];
}

/// The English band title, matching MADMacDocument -displayTitleForSection: (localization is 6e).
static NSString *MADCLIServeSectionTitle(RptqDocumentSection *section) {
	switch (section.type) {
		case MADDocumentSectionTypeReportHeader: return @"Report Header";
		case MADDocumentSectionTypePageHeader: return @"Page Header";
		case MADDocumentSectionTypeBody: return @"Report Detail";
		case MADDocumentSectionTypePageFooter: return @"Page Footer";
		case MADDocumentSectionTypeReportFooter: return @"Report Footer";
		case MADDocumentSectionTypeGroupHeader: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0 ? [NSString stringWithFormat: @"Group Header (%@)", field] : @"Group Header";
		}
		case MADDocumentSectionTypeGroupFooter: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0 ? [NSString stringWithFormat: @"Group Footer (%@)", field] : @"Group Footer";
		}
		default: return @"Section";
	}
}

/// The designer's "interface height" — the value the inspector edits and that
/// setInterfaceHeight: stores as layoutHeight (height is layoutHeight + 44).
static double MADCLIServeSectionHeight(RptqDocumentSection *section) {
	double h = section.layoutHeight;
	if (h < 1.0) h = MAX(36.0, section.height - 44.0);
	return h;
}

/// The authoritative section-local frame, as the Mac's elementRectInSectionContent: reads it.
static CGRect MADCLIServeElementRect(RptqDocumentElement *element) {
	CGFloat x = 0.0, y = 0.0, w = 120.0, h = 22.0;
	if (element.rect && element.rect.origin) {
		x = element.rect.origin.x;
		y = element.rect.origin.y;
	}
	if (x == 0.0 && y == 0.0 && element.dropPoint && (element.dropPoint.x != 0.0 || element.dropPoint.y != 0.0)) {
		x = element.dropPoint.x;
		y = element.dropPoint.y;
	}
	if (element.rect && element.rect.size) {
		if (element.rect.size.width > 0.0) w = element.rect.size.width;
		if (element.rect.size.height > 0.0) h = element.rect.size.height;
	}
	return CGRectMake(x, y, w, h);
}

static void MADCLIServeSetElementOrigin(RptqDocumentElement *element, double x, double y) {
	[element setOriginPoint: CGPointMake(x, y)];
	if (element.dropPoint) {
		element.dropPoint.x = (float)x;
		element.dropPoint.y = (float)y;
	}
}

/// Grows the section's stored height when an element's bottom extends past it, mirroring the
/// Mac's attachElement:/moveElement:toSection:atOrigin: auto-grow so a low-placed element is
/// not clipped by the stored layout height.
static void MADCLIServeGrowSectionForElement(RptqDocumentSection *section, RptqDocumentElement *element) {
	CGRect rect = MADCLIServeElementRect(element);
	if (rect.origin.y + rect.size.height + 6.0 > section.layoutHeight) {
		[section setInterfaceHeight: ceil(rect.origin.y + rect.size.height + 8.0)];
	}
}

static RptqDocumentSection *MADCLIServeSectionForElement(id <MADDocumentDataProtocol> document, RptqQuery *query, RptqDocumentElement *element) {
	if (element.inSectionRow && element.inSectionRow.inSection) return element.inSectionRow.inSection;
	for (RptqDocumentSection *section in MADCLIServeOrderedSections(document, query)) {
		for (RptqDocumentSectionRows *row in section.hasRows) {
			if ([row.hasObjects containsObject: element]) return section;
		}
	}
	return nil;
}

/// YES when the section is part of the query's own layout (its five structural sections
/// or its group bands), so a cross-node section id cannot touch another node.
static BOOL MADCLIServeSectionBelongsToQuery(id <MADDocumentDataProtocol> document, RptqQuery *query, RptqDocumentSection *section) {
	if (section == nil || query == nil) return NO;
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	for (RptqDocumentSection *candidate in [query orderedLayoutSectionsForDocument: doc]) {
		if (candidate == section) return YES;
	}
	return NO;
}

static BOOL MADCLIServeElementBelongsToQuery(id <MADDocumentDataProtocol> document, RptqQuery *query, RptqDocumentElement *element) {
	if (element == nil || query == nil) return NO;
	return MADCLIServeSectionBelongsToQuery(document, query, element.inSectionRow.inSection);
}

static RptqQueryField *MADCLIServeFirstQueryField(RptqQuery *query) {
	for (RptqQueryTable *table in query.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			return field;
		}
	}
	return nil;
}

static NSDictionary *MADCLIServeElementDict(RptqDocumentElement *element, int64_t sectionId) {
	CGRect rect = MADCLIServeElementRect(element);

	NSString *text = @"";
	int64_t fieldID = 0;
	NSString *tableID = @"";
	NSString *columnID = @"";
	int16_t functionType = 0;
	int16_t groupType = 0;
	int32_t groupNumber = 0;
	NSDictionary *barcodeInfo = nil;
	NSDictionary *imageInfo = nil;

	if ([element isKindOfClass: [RptqDocumentElementLabel class]]) {
		text = ((RptqDocumentElementLabel *)element).text ?: @"";
	} else if ([element isKindOfClass: [RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)element;
		text = df.text ?: @"";
		tableID = df.tableID ?: @"";
		columnID = df.fieldID ?: @"";
		if (df.referencesQueryField) fieldID = df.referencesQueryField.identifier;
	} else if ([element isKindOfClass: [RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)element;
		if (bc.useStaticInput1) text = bc.inputStatic1 ?: @"";
		if (bc.referencesField1) fieldID = bc.referencesField1.identifier;

		// A sample symbol for the designer's canvas, so the Windows composer shows
		// the barcode the options actually produce rather than a placeholder.
		NSString *sample = (bc.useStaticInput1 && bc.inputStatic1.length > 0)
			? bc.inputStatic1
			: (bc.referencesField1.databaseSchemaField.name ?: @"1234567890");
		MADBarcode *drawing = [MADBarcode newBarcode:bc input1:sample input2:@""];
		NSData *preview = [drawing renderedPNGData];
		barcodeInfo = @{
			@"type": @(bc.barcodeType),
			@"name": [MADBarcode newBarcodeNameForType: barcodeTypeForInt(bc.barcodeType)] ?: @"",
			@"humanReadable": @(bc.humanReadable),
			@"borderStyle": @(bc.barcodeBorderStyle),
			@"useStaticInput": @(bc.useStaticInput1),
			@"staticInput": bc.inputStatic1 ?: @"",
			@"field": @(bc.referencesField1 ? bc.referencesField1.identifier : 0),
			@"preview": [preview base64EncodedStringWithOptions: 0] ?: @"",
		};
	} else if ([element isKindOfClass: [RptqDocumentElementImage class]]) {
		// The picture itself, in the store's PNG wire format, so the designer's
		// canvas can show what will print.
		NSData *png = ((RptqDocumentElementImage *)element).pngData;
		imageInfo = @{ @"data": [png base64EncodedStringWithOptions: 0] ?: @"" };
	} else if ([element isKindOfClass: [RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)element;
		functionType = (int16_t)agg.functionType;
		groupType = (int16_t)agg.groupType;
		groupNumber = agg.groupNumber;
		if (agg.aggregateField) fieldID = agg.aggregateField.identifier;
	}

	CGFloat borderTop = 0.0, borderBottom = 0.0, borderLeft = 0.0, borderRight = 0.0;
	if (element.border && element.border.width) {
		RptqDirectionalAsymmetry *bw = element.border.width;
		borderTop = bw.top; borderBottom = bw.bottom; borderLeft = bw.left; borderRight = bw.right;
	}
	CGFloat padding = element.padding ? element.padding.left : 0.0;
	CGFloat margin = element.margin ? element.margin.left : 0.0;

	BOOL bold = NO, italic = NO, underline = NO, strikethrough = NO;
	if (element.textStyle) {
		bold = element.textStyle.bold;
		italic = element.textStyle.italic;
		underline = element.textStyle.underline;
		strikethrough = element.textStyle.strikethrough;
	}
	int16_t hAlign = element.alignment ? element.alignment.horizontal : MADHorizontalAlignmentLeft;
	int16_t vAlign = element.alignment ? element.alignment.vertical : MADVerticalAlignmentCenter;

	NSMutableDictionary *dictionary = [@{
		@"id": @(element.identifier),
		@"type": @(element.type),
		@"section": @(sectionId),
		@"x": @(rect.origin.x), @"y": @(rect.origin.y),
		@"w": @(rect.size.width), @"h": @(rect.size.height),
		@"text": text,
		@"field": @(fieldID),
		@"table": tableID,
		@"column": columnID,
		@"function": @(functionType),
		@"scope": @(groupType),
		@"group": @(groupNumber),
		@"fontname": element.fontname ?: @"",
		@"fontsize": @(element.fontsize),
		@"bold": @(bold), @"italic": @(italic), @"underline": @(underline), @"strikethrough": @(strikethrough),
		@"hAlign": @(hAlign), @"vAlign": @(vAlign),
		@"borderTop": @(borderTop), @"borderBottom": @(borderBottom),
		@"borderLeft": @(borderLeft), @"borderRight": @(borderRight),
		@"padding": @(padding), @"margin": @(margin),
	} mutableCopy];
	// Only a barcode or image element carries its nested member; every other
	// element's shape is exactly what it was.
	if (barcodeInfo != nil) dictionary[@"barcode"] = barcodeInfo;
	if (imageInfo != nil) dictionary[@"image"] = imageInfo;
	return dictionary;
}

static NSDictionary *MADCLIServeLayoutModelDict(id <MADDocumentDataProtocol> document, RptqQuery *query) {
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	if (query == nil) query = doc.rootQuery ?: doc.defaultDatabase.defaultQuery;

	NSMutableArray <NSDictionary *> *sections = [NSMutableArray array];
	NSMutableArray <NSDictionary *> *elements = [NSMutableArray array];
	for (RptqDocumentSection *section in MADCLIServeOrderedSections(document, query)) {
		NSString *groupField = nil;
		if (section.type == MADDocumentSectionTypeGroupHeader || section.type == MADDocumentSectionTypeGroupFooter) {
			groupField = [section.inGroup fieldNameNice];
		}
		[sections addObject: @{
			@"id": @(section.identifier),
			@"type": @(section.type),
			@"title": MADCLIServeSectionTitle(section),
			@"height": @(MADCLIServeSectionHeight(section)),
			@"visible": @(section.visibility),
			@"pageBreak": @([section producesFormFeed]),
			@"groupField": groupField.length > 0 ? groupField : [NSNull null],
		}];
		for (RptqDocumentSectionRows *row in section.hasRows) {
			for (RptqDocumentElement *element in row.hasObjects) {
				[elements addObject: MADCLIServeElementDict(element, section.identifier)];
			}
		}
	}

	NSMutableArray <NSDictionary *> *fields = [NSMutableArray array];
	if ([query isComposing]) {
		// A composing node's (root or non-root composer) designer field list is its
		// ordered outputs (by outputKey), so a placed data field binds to a persisted
		// output key rather than a source alias.
		NSArray <RptqQueryField *> *outputs = [query orderedOutputFieldsWithError: NULL] ?: @[];
		for (RptqQueryField *field in outputs) {
			NSString *name = field.outputKey ?: (field.databaseSchemaField.name ?: @"");
			NSString *table = field.inQueryTable.upstreamQuery.name ?: @"";
			[fields addObject: @{ @"id": @(field.identifier), @"name": name, @"table": table, @"display": name }];
		}
	} else {
		NSMutableArray <RptqQueryTable *> *tables = [[query.hasQueryTables allObjects] mutableCopy];
		[tables sortUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"dropIndex" ascending: YES]]];
		NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey: @"databaseSchemaField.name"
																 ascending: YES
																  selector: @selector(localizedCaseInsensitiveCompare:)];
		for (RptqQueryTable *table in tables) {
			NSString *alias = table.alias.length > 0 ? table.alias : (table.databaseSchemaTable.name ?: @"");
			NSArray <RptqQueryField *> *sorted = [[table.hasQueryFields allObjects] sortedArrayUsingDescriptors: @[byName]];
			for (RptqQueryField *field in sorted) {
				NSString *name = field.databaseSchemaField.name ?: @"";
				[fields addObject: @{
					@"id": @(field.identifier),
					@"name": name,
					@"table": alias,
					@"display": [NSString stringWithFormat: @"%@.%@", alias, name],
				}];
			}
		}
	}

	return @{
		@"paperSize": @(doc.papersize),
		@"sections": sections,
		@"elements": elements,
		@"fields": fields,
	};
}

static void MADCLIServeLayoutModel(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;
	NSError *error = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(entry.document.document, params, &error);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	// A legacy revision-3 leaf has no sections; materialize its five empty sections so
	// the client always has section ids to author against (persisted by the next save).
	[query ensureStructuralSectionsInContext: entry.document.document.storeContext];
	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(entry.document.document, query));
}

// The symbologies the designer's picker offers: MADBarcode's own name table, so
// the Windows composer cannot drift from the Apple one.
static void MADCLIServeBarcodeTypes(id requestID) {
	NSDictionary <NSNumber *, NSString *> *names = [MADBarcode newDictionaryNames] ?: @{};
	NSArray <NSNumber *> *keys = [names.allKeys sortedArrayUsingComparator: ^NSComparisonResult(NSNumber *a, NSNumber *b) {
		return [names[a] localizedCaseInsensitiveCompare: names[b]];
	}];

	NSMutableArray <NSDictionary *> *types = [NSMutableArray arrayWithCapacity: keys.count];
	for (NSNumber *key in keys) {
		[types addObject: @{ @"id": key, @"name": names[key] }];
	}
	MADCLIServeWriteResult(requestID, @{ @"types": types });
}

static void MADCLIServeEnsureFirstRow(RptqDocumentSection *section, RptqStoreContext *context) {
	if (section.hasRows.count > 0) return;
	RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentSectionRows class]) identifier: 0];
	row.rowNumber = 0;
	row.layoutHeight = MAX(40.0, section.layoutHeight);
	row.inSection = section;
	[section addHasRowsFixed: row];
}

static void MADCLIServeAddElement(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSString *kind = MADCLIServeOptionalString(params, @"kind");
	int64_t sectionID = [params[@"section"] isKindOfClass: [NSNumber class]] ? [params[@"section"] longLongValue] : 0;
	double x = [params[@"x"] isKindOfClass: [NSNumber class]] ? [params[@"x"] doubleValue] : 0.0;
	double y = [params[@"y"] isKindOfClass: [NSNumber class]] ? [params[@"y"] doubleValue] : 0.0;
	if (kind == nil || sectionID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"add-element needs a kind and a section.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *section = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: sectionID];
	if (section == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", sectionID]);
		return;
	}
	if (!MADCLIServeSectionBelongsToQuery(document, query, section)) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"section %lld is not part of query %lld's layout.", sectionID, query.identifier]);
		return;
	}
	MADCLIServeEnsureFirstRow(section, context);

	RptqDocumentElement *element = nil;
	double w = 120.0, h = 22.0;
	if ([kind isEqualToString: @"label"]) {
		RptqDocumentElementLabel *lbl = (RptqDocumentElementLabel *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
		lbl.type = (int16_t)MADPrintPageElementTypeLabelStatic;
		lbl.text = @"Static Label";
		w = 124.0; h = 22.0;
		element = lbl;
	} else if ([kind isEqualToString: @"data-field"]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		df.type = (int16_t)MADPrintPageElementTypeLabelDynamic;
		RptqQueryField *bound = MADCLIServeFirstQueryField(query);
		if (bound) {
			df.referencesQueryField = bound;
			df.fieldID = bound.databaseSchemaField.name;
			df.tableID = bound.inQueryTable.alias ?: bound.inQueryTable.databaseSchemaTable.name;
			df.text = [NSString stringWithFormat: @"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
		} else {
			df.text = @"[Data Field]";
		}
		w = 140.0; h = 22.0;
		element = df;
	} else if ([kind isEqualToString: @"aggregate"]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementAggregate class]) identifier: 0];
		agg.type = (int16_t)MADPrintPageElementTypeAggregate;
		agg.functionType = MTAggregateFunctionTypeSum;
		if (section.type == MADDocumentSectionTypeGroupHeader || section.type == MADDocumentSectionTypeGroupFooter) {
			agg.groupType = MTAggregateGroupByTypeSection;
			agg.groupNumber = 1;
		} else if (section.type == MADDocumentSectionTypePageHeader || section.type == MADDocumentSectionTypePageFooter) {
			agg.groupType = MTAggregateGroupByTypePage;
		} else {
			agg.groupType = MTAggregateGroupByTypeReport;
		}
		agg.aggregateField = MADCLIServeFirstQueryField(query);
		w = 144.0; h = 22.0;
		element = agg;
	} else if ([kind isEqualToString: @"image"]) {
		// The PNG arrives as base64, the same encoding the snapshot uses; decode
		// before inserting so a malformed request leaves no half-made element.
		NSData *png = nil;
		NSString *dataString = MADCLIServeOptionalString(params, @"data");
		if (dataString.length > 0) {
			png = [[NSData alloc] initWithBase64EncodedString: dataString options: 0];
			if (png == nil) {
				MADCLIServeWriteError(requestID, MADCLIExitUsage, @"data is not valid base64.");
				return;
			}
		}
		RptqDocumentElementImage *img = (RptqDocumentElementImage *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementImage class]) identifier: 0];
		img.type = (int16_t)MADPrintPageElementTypeImage;
		if (png != nil) [img setPngData: png];
		w = 96.0; h = 64.0;
		element = img;
	} else if ([kind isEqualToString: @"line"]) {
		RptqDocumentElementLabel *line = (RptqDocumentElementLabel *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
		line.type = (int16_t)MADPrintPageElementTypeLabelStatic;
		line.text = @"";
		if (line.border && line.border.width) line.border.width.bottom = 1.5f;
		w = 320.0; h = 8.0;
		element = line;
	} else if ([kind isEqualToString: @"barcode"]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementBarcode class]) identifier: 0];
		bc.type = (int16_t)MADPrintPageElementTypeBarcode;
		bc.barcodeType = (int16_t)MADBarcodeTypeCODE128;
		bc.humanReadable = YES;
		bc.useStaticInput1 = YES;
		bc.inputStatic1 = @"MAD-2026";
		bc.scale = 1.0f;
		bc.barcodeHeight = 40;
		w = 160.0; h = 48.0;
		element = bc;
	} else {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown element kind '%@'.", kind]);
		return;
	}

	[element setSizeWidth: (float)w height: (float)h];
	[section addDocumentObject: element withDropPoint: CGPointMake(x, y) managedObjectContext: context];
	MADCLIServeSetElementOrigin(element, x, y);
	element.inSectionRow = section.hasRows.firstObject;
	MADCLIServeGrowSectionForElement(section, element);

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeRemoveElements(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	if (![params[@"elements"] isKindOfClass: [NSArray class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in params[@"elements"]) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, element)) continue;
		for (RptqDocumentSection *section in MADCLIServeOrderedSections(document, query)) {
			for (RptqDocumentSectionRows *row in section.hasRows) {
				if ([row.hasObjects containsObject: element]) {
					[row removeHasObjectsObject: element];
				}
			}
		}
		element.inSectionRow = nil;
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeMoveElements(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSArray *ids = [params[@"elements"] isKindOfClass: [NSArray class]] ? params[@"elements"] : nil;
	int64_t targetSectionID = [params[@"section"] isKindOfClass: [NSNumber class]] ? [params[@"section"] longLongValue] : 0;
	if (ids == nil || targetSectionID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"move-elements needs an elements array and a section.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *target = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: targetSectionID];
	if (target == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", targetSectionID]);
		return;
	}
	if (!MADCLIServeSectionBelongsToQuery(document, query, target)) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"section %lld is not part of query %lld's layout.", targetSectionID, query.identifier]);
		return;
	}
	MADCLIServeEnsureFirstRow(target, context);
	RptqDocumentSectionRows *targetRow = target.hasRows.firstObject;

	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, element)) continue;
		for (RptqDocumentSection *section in MADCLIServeOrderedSections(document, query)) {
			for (RptqDocumentSectionRows *row in section.hasRows) {
				if ([row.hasObjects containsObject: element]) {
					[row removeHasObjectsObject: element];
				}
			}
		}
		[targetRow addHasObjectsObject: element];
		element.inSectionRow = targetRow;
		MADCLIServeGrowSectionForElement(target, element);
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetElementGeometry(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSArray *array = [params[@"elements"] isKindOfClass: [NSArray class]] ? params[@"elements"] : nil;
	if (array == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	for (NSDictionary *item in array) {
		if (![item isKindOfClass: [NSDictionary class]]) continue;
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [item[@"id"] longLongValue]];
		if (element == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, element)) continue;
		double x = [item[@"x"] isKindOfClass: [NSNumber class]] ? [item[@"x"] doubleValue] : 0.0;
		double y = [item[@"y"] isKindOfClass: [NSNumber class]] ? [item[@"y"] doubleValue] : 0.0;
		double w = [item[@"w"] isKindOfClass: [NSNumber class]] ? [item[@"w"] doubleValue] : 0.0;
		double h = [item[@"h"] isKindOfClass: [NSNumber class]] ? [item[@"h"] doubleValue] : 0.0;
		MADCLIServeSetElementOrigin(element, x, y);
		[element setSizeWidth: (float)w height: (float)h];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetElementContent(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t elementID = [params[@"element"] isKindOfClass: [NSNumber class]] ? [params[@"element"] longLongValue] : 0;
	NSDictionary *content = [params[@"content"] isKindOfClass: [NSDictionary class]] ? params[@"content"] : @{};
	if (elementID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"element must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: elementID];
	if (element == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown element %lld.", elementID]);
		return;
	}
	if (!MADCLIServeElementBelongsToQuery(document, query, element)) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"element %lld is not part of query %lld's layout.", elementID, query.identifier]);
		return;
	}

	if ([element isKindOfClass: [RptqDocumentElementLabel class]]) {
		if ([content[@"text"] isKindOfClass: [NSString class]]) {
			((RptqDocumentElementLabel *)element).text = content[@"text"];
		}
	} else if ([element isKindOfClass: [RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)element;
		if ([content[@"field"] isKindOfClass: [NSNumber class]]) {
			RptqQueryField *field = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: [content[@"field"] longLongValue]];
			if (field) {
				df.referencesQueryField = field;
				df.fieldID = field.databaseSchemaField.name;
				df.tableID = field.inQueryTable.alias ?: field.inQueryTable.databaseSchemaTable.name;
				df.text = [NSString stringWithFormat: @"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
			}
		} else if ([content[@"text"] isKindOfClass: [NSString class]]) {
			df.text = content[@"text"];
		}
	} else if ([element isKindOfClass: [RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)element;
		if ([content[@"function"] isKindOfClass: [NSNumber class]]) agg.functionType = (MTAggregateFunctionType)[content[@"function"] integerValue];
		if ([content[@"scope"] isKindOfClass: [NSNumber class]]) agg.groupType = (MTAggregateGroupByType)[content[@"scope"] integerValue];
		if ([content[@"group"] isKindOfClass: [NSNumber class]]) agg.groupNumber = (int32_t)[content[@"group"] integerValue];
		if ([content[@"field"] isKindOfClass: [NSNumber class]]) {
			agg.aggregateField = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: [content[@"field"] longLongValue]];
		}
	} else if ([element isKindOfClass: [RptqDocumentElementImage class]]) {
		// The picture, base64 PNG; an empty string clears it.
		if ([content[@"data"] isKindOfClass: [NSString class]]) {
			NSString *dataString = content[@"data"];
			NSData *png = nil;
			if (dataString.length > 0) {
				png = [[NSData alloc] initWithBase64EncodedString: dataString options: 0];
				if (png == nil) {
					MADCLIServeWriteError(requestID, MADCLIExitUsage, @"data is not valid base64.");
					return;
				}
			}
			[(RptqDocumentElementImage *)element setPngData: png];
		}
	} else if ([element isKindOfClass: [RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)element;
		if ([content[@"barcodeType"] isKindOfClass: [NSNumber class]]) {
			bc.barcodeType = (int16_t)[content[@"barcodeType"] integerValue];
		}
		if ([content[@"humanReadable"] isKindOfClass: [NSNumber class]]) {
			bc.humanReadable = [content[@"humanReadable"] boolValue];
		}
		if ([content[@"borderStyle"] isKindOfClass: [NSNumber class]]) {
			bc.barcodeBorderStyle = (int16_t)[content[@"borderStyle"] integerValue];
		}
		// A field binds the input to the query; field 0 (or none) switches back to
		// the static string, which the text member edits.
		if ([content[@"field"] isKindOfClass: [NSNumber class]]) {
			int64_t fieldID = [content[@"field"] longLongValue];
			RptqQueryField *field = fieldID != 0
				? (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: fieldID]
				: nil;
			if (field != nil) {
				bc.useStaticInput1 = NO;
				bc.referencesField1 = field;
				bc.inputField1 = field.databaseSchemaField.name;
			} else {
				bc.useStaticInput1 = YES;
				bc.referencesField1 = nil;
			}
		}
		if ([content[@"text"] isKindOfClass: [NSString class]]) {
			bc.useStaticInput1 = YES;
			bc.referencesField1 = nil;
			bc.inputStatic1 = content[@"text"];
		}
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetElementTypography(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSArray *ids = [params[@"elements"] isKindOfClass: [NSArray class]] ? params[@"elements"] : nil;
	if (ids == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, element)) continue;
		if ([params[@"fontname"] isKindOfClass: [NSString class]]) element.fontname = params[@"fontname"];
		if ([params[@"fontsize"] isKindOfClass: [NSNumber class]]) element.fontsize = [params[@"fontsize"] doubleValue];
		if ([params[@"bold"] isKindOfClass: [NSNumber class]]) element.textStyle.bold = [params[@"bold"] boolValue];
		if ([params[@"italic"] isKindOfClass: [NSNumber class]]) element.textStyle.italic = [params[@"italic"] boolValue];
		if ([params[@"underline"] isKindOfClass: [NSNumber class]]) element.textStyle.underline = [params[@"underline"] boolValue];
		if ([params[@"strikethrough"] isKindOfClass: [NSNumber class]]) element.textStyle.strikethrough = [params[@"strikethrough"] boolValue];
		if ([params[@"hAlign"] isKindOfClass: [NSNumber class]]) element.alignment.horizontal = (int16_t)[params[@"hAlign"] integerValue];
		if ([params[@"vAlign"] isKindOfClass: [NSNumber class]]) element.alignment.vertical = (int16_t)[params[@"vAlign"] integerValue];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetElementBoxModel(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSArray *ids = [params[@"elements"] isKindOfClass: [NSArray class]] ? params[@"elements"] : nil;
	if (ids == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, element)) continue;
		if ([params[@"borderTop"] isKindOfClass: [NSNumber class]]) element.border.width.top = (float)[params[@"borderTop"] doubleValue];
		if ([params[@"borderBottom"] isKindOfClass: [NSNumber class]]) element.border.width.bottom = (float)[params[@"borderBottom"] doubleValue];
		if ([params[@"borderLeft"] isKindOfClass: [NSNumber class]]) element.border.width.left = (float)[params[@"borderLeft"] doubleValue];
		if ([params[@"borderRight"] isKindOfClass: [NSNumber class]]) element.border.width.right = (float)[params[@"borderRight"] doubleValue];
		if ([params[@"padding"] isKindOfClass: [NSNumber class]]) {
			float pad = (float)[params[@"padding"] doubleValue];
			element.padding.top = pad; element.padding.bottom = pad; element.padding.left = pad; element.padding.right = pad;
		}
		if ([params[@"margin"] isKindOfClass: [NSNumber class]]) {
			float mar = (float)[params[@"margin"] doubleValue];
			element.margin.top = mar; element.margin.bottom = mar; element.margin.left = mar; element.margin.right = mar;
		}
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetSection(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	int64_t sectionID = [params[@"section"] isKindOfClass: [NSNumber class]] ? [params[@"section"] longLongValue] : 0;
	if (sectionID == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"section must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *section = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: sectionID];
	if (section == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", sectionID]);
		return;
	}
	if (!MADCLIServeSectionBelongsToQuery(document, query, section)) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"section %lld is not part of query %lld's layout.", sectionID, query.identifier]);
		return;
	}
	if ([params[@"height"] isKindOfClass: [NSNumber class]]) [section setInterfaceHeight: [params[@"height"] doubleValue]];
	if ([params[@"visible"] isKindOfClass: [NSNumber class]]) section.visibility = [params[@"visible"] boolValue];
	if ([params[@"pageBreak"] isKindOfClass: [NSNumber class]]) [section setProducesFormFeed: [params[@"pageBreak"] boolValue]];

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

static void MADCLIServeSetPaperSize(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	if (![params[@"paperSize"] isKindOfClass: [NSNumber class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"paperSize must be a number.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	doc.papersize = (int16_t)[params[@"paperSize"] integerValue];

	// The layout model lives in the store, but a render document caches its MTPaper the
	// first time it lays a page out.  Set the paper on the render document too -- the call
	// the Mac viewer makes before it refreshes -- and re-format a report that is already
	// laid out, so the new size reaches an export that follows without another refresh.
	if ([document respondsToSelector: @selector(setPaperType:)]) {
		id <MADDocumentRenderProtocol> renderDocument = (id <MADDocumentRenderProtocol>)document;
		[renderDocument setPaperType: (MTPaperType)doc.papersize];
		if (document.didRefresh && [renderDocument respondsToSelector: @selector(format)]) {
			[renderDocument format];
		}
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, nil));
}

static RptqDocumentElement *MADCLIServeDuplicateElement(RptqDocumentElement *src, RptqStoreContext *context) {
	RptqDocumentElement *dst = nil;
	if ([src isKindOfClass: [RptqDocumentElementLabel class]]) {
		RptqDocumentElementLabel *dup = (RptqDocumentElementLabel *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
		dup.type = src.type;
		dup.text = [((RptqDocumentElementLabel *)src).text copy];
		dst = dup;
	} else if ([src isKindOfClass: [RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *s = (RptqDocumentElementLabelDataField *)src;
		RptqDocumentElementLabelDataField *dup = (RptqDocumentElementLabelDataField *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier: 0];
		dup.type = src.type;
		dup.referencesQueryField = s.referencesQueryField;
		dup.fieldID = [s.fieldID copy];
		dup.tableID = [s.tableID copy];
		dup.text = [s.text copy];
		dst = dup;
	} else if ([src isKindOfClass: [RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *s = (RptqDocumentElementAggregate *)src;
		RptqDocumentElementAggregate *dup = (RptqDocumentElementAggregate *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementAggregate class]) identifier: 0];
		dup.type = src.type;
		dup.functionType = s.functionType;
		dup.groupType = s.groupType;
		dup.groupNumber = s.groupNumber;
		dup.aggregateField = s.aggregateField;
		dst = dup;
	} else if ([src isKindOfClass: [RptqDocumentElementImage class]]) {
		RptqDocumentElementImage *s = (RptqDocumentElementImage *)src;
		RptqDocumentElementImage *dup = (RptqDocumentElementImage *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementImage class]) identifier: 0];
		dup.type = src.type;
		[dup setPngData: [[s pngData] copy]];
		dst = dup;
	} else if ([src isKindOfClass: [RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *s = (RptqDocumentElementBarcode *)src;
		RptqDocumentElementBarcode *dup = (RptqDocumentElementBarcode *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementBarcode class]) identifier: 0];
		dup.type = src.type;
		dup.barcodeType = s.barcodeType;
		dup.humanReadable = s.humanReadable;
		dup.showErrorMessage = s.showErrorMessage;
		dup.barcodeBorderStyle = s.barcodeBorderStyle;
		dup.barcodeBorderType = s.barcodeBorderType;
		dup.barcodeBorderWidth = s.barcodeBorderWidth;
		dup.barcodeHeight = s.barcodeHeight;
		dup.whitespaceWidth = s.whitespaceWidth;
		dup.scale = s.scale;
		dup.add2dComponent = s.add2dComponent;
		dup.inputMode = s.inputMode;
		dup.option1 = s.option1;
		dup.option2 = s.option2;
		dup.option3 = s.option3;
		dup.useStaticInput1 = s.useStaticInput1;
		dup.useStaticInput2 = s.useStaticInput2;
		dup.inputStatic1 = [s.inputStatic1 copy];
		dup.inputStatic2 = [s.inputStatic2 copy];
		dup.inputField1 = [s.inputField1 copy];
		dup.inputField2 = [s.inputField2 copy];
		dup.referencesField1 = s.referencesField1;
		dup.referencesField2 = s.referencesField2;
		dst = dup;
	}
	return dst;
}

static void MADCLIServeCopyElementStyle(RptqDocumentElement *dst, RptqDocumentElement *src) {
	dst.fontname = [src.fontname copy];
	dst.fontsize = src.fontsize;
	if (dst.textStyle && src.textStyle) {
		dst.textStyle.bold = src.textStyle.bold;
		dst.textStyle.italic = src.textStyle.italic;
		dst.textStyle.underline = src.textStyle.underline;
		dst.textStyle.strikethrough = src.textStyle.strikethrough;
	}
	if (dst.alignment && src.alignment) {
		dst.alignment.horizontal = src.alignment.horizontal;
		dst.alignment.vertical = src.alignment.vertical;
	}
	if (dst.border && dst.border.width && src.border && src.border.width) {
		dst.border.width.top = src.border.width.top;
		dst.border.width.bottom = src.border.width.bottom;
		dst.border.width.left = src.border.width.left;
		dst.border.width.right = src.border.width.right;
	}
	if (dst.padding && src.padding) {
		dst.padding.top = src.padding.top;
		dst.padding.bottom = src.padding.bottom;
		dst.padding.left = src.padding.left;
		dst.padding.right = src.padding.right;
	}
	if (dst.margin && src.margin) {
		dst.margin.top = src.margin.top;
		dst.margin.bottom = src.margin.bottom;
		dst.margin.left = src.margin.left;
		dst.margin.right = src.margin.right;
	}
}

static void MADCLIServeDuplicateElements(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	NSArray *ids = [params[@"elements"] isKindOfClass: [NSArray class]] ? params[@"elements"] : nil;
	if (ids == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *queryError = nil;
	RptqQuery *query = MADCLIServeResolveLayoutQuery(document, params, &queryError);
	if (query == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(queryError));
		return;
	}
	[query ensureStructuralSectionsInContext: document.storeContext];
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *src = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (src == nil) continue;
		if (!MADCLIServeElementBelongsToQuery(document, query, src)) continue;
		RptqDocumentSection *section = MADCLIServeSectionForElement(document, query, src);
		if (section == nil) continue;
		MADCLIServeEnsureFirstRow(section, context);

		CGRect rect = MADCLIServeElementRect(src);
		RptqDocumentElement *dup = MADCLIServeDuplicateElement(src, context);
		if (dup == nil) continue;
		MADCLIServeCopyElementStyle(dup, src);
		[dup setSizeWidth: (float)rect.size.width height: (float)rect.size.height];

		double nx = rect.origin.x + 16.0;
		double ny = rect.origin.y + 12.0;
		[section addDocumentObject: dup withDropPoint: CGPointMake(nx, ny) managedObjectContext: context];
		MADCLIServeSetElementOrigin(dup, nx, ny);
		dup.inSectionRow = section.hasRows.firstObject;
		MADCLIServeGrowSectionForElement(section, dup);
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document, query));
}

#pragma mark - Dispatch

/// Handles one parsed request.  Returns YES when the session should end (shutdown).
static BOOL MADCLIServeDispatch(NSDictionary *request, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents) {
	id requestID = request[@"id"] ?: [NSNull null];
	NSString *method = [request[@"method"] isKindOfClass: [NSString class]] ? request[@"method"] : nil;
	NSDictionary *params = [request[@"params"] isKindOfClass: [NSDictionary class]] ? request[@"params"] : @{};

	if (method.length == 0) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"missing or invalid \"method\".");
		return NO;
	}

	@try {
		if ([method isEqualToString: MADCLIServeMethodEngineInfo]) {
			MADCLIServeWriteResult(requestID, MADCLIEngineInfoDictionary());
		} else if ([method isEqualToString: MADCLIServeMethodOpen]) {
			MADCLIServeOpen(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodCreate]) {
			MADCLIServeCreate(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodCreateEmpty]) {
			MADCLIServeCreateEmpty(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodTestConnection]) {
			MADCLIServeTestConnection(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodConnection]) {
			MADCLIServeConnection(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodApplyConnection]) {
			MADCLIServeApplyConnection(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodDescribe]) {
			MADCLIServeDescribe(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodQuery]) {
			MADCLIServeQuery(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodQueryModel]) {
			MADCLIServeQueryModel(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodDocumentInfo]) {
			MADCLIServeDocumentInfo(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddRoot]) {
			MADCLIServeAddRoot(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddSource]) {
			MADCLIServeAddSource(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddUpstream]) {
			MADCLIServeAddUpstream(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodImportChild]) {
			MADCLIServeImportChild(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodConvert]) {
			MADCLIServeConvert(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetRootOutputs]) {
			MADCLIServeSetRootOutputs(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddTable]) {
			MADCLIServeAddTable(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodRemoveTable]) {
			MADCLIServeRemoveTable(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddLink]) {
			MADCLIServeAddLink(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetLinkType]) {
			MADCLIServeSetLinkType(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSwapLink]) {
			MADCLIServeSwapLink(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodDeleteLink]) {
			MADCLIServeDeleteLink(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddPredicate]) {
			MADCLIServeAddPredicate(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodRemovePredicate]) {
			MADCLIServeRemovePredicate(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddGroup]) {
			MADCLIServeAddGroup(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodRemoveGroup]) {
			MADCLIServeRemoveGroup(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodValidateSQL]) {
			MADCLIServeValidateSQL(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodApplySQL]) {
			MADCLIServeApplySQL(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodBarcodeTypes]) {
			MADCLIServeBarcodeTypes(requestID);
		} else if ([method isEqualToString: MADCLIServeMethodLayoutModel]) {
			MADCLIServeLayoutModel(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodAddElement]) {
			MADCLIServeAddElement(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodRemoveElements]) {
			MADCLIServeRemoveElements(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodDuplicateElements]) {
			MADCLIServeDuplicateElements(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodMoveElements]) {
			MADCLIServeMoveElements(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetElementGeometry]) {
			MADCLIServeSetElementGeometry(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetElementContent]) {
			MADCLIServeSetElementContent(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetElementTypography]) {
			MADCLIServeSetElementTypography(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetElementBoxModel]) {
			MADCLIServeSetElementBoxModel(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetSection]) {
			MADCLIServeSetSection(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodSetPaperSize]) {
			MADCLIServeSetPaperSize(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodRefresh]) {
			MADCLIServeRefresh(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodExport]) {
			MADCLIServeExport(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodNodeResult]) {
			MADCLIServeNodeResult(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodWrite]) {
			MADCLIServeWriteCopy(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodShutdown]) {
			MADCLIServeWriteResult(requestID, @{});
			return YES;
		} else {
			MADCLIServeWriteError(requestID, MADCLIExitUsage,
				[NSString stringWithFormat: @"unknown method '%@'.", method]);
		}
	} @catch (NSException *exception) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage,
			[NSString stringWithFormat: @"engine error: %@", exception.reason ?: exception.name]);
	}

	return NO;
}

/// Parses one line and dispatches it.  Blank lines are ignored; a line that is not a
/// JSON object is answered with a malformed-request error and the session continues.
static BOOL MADCLIServeHandleLine(const char *line, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents) {
	NSString *trimmed = [[NSString stringWithUTF8String: line]
		stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmed.length == 0) return NO;

	NSData *data = [trimmed dataUsingEncoding: NSUTF8StringEncoding];
	NSError *parseError = nil;
	id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &parseError];
	if (object == nil || ![object isKindOfClass: [NSDictionary class]]) {
		MADCLIServeWriteError([NSNull null], MADCLIExitUsage,
			[NSString stringWithFormat: @"malformed request: %@",
				parseError.localizedDescription ?: @"the request is not a JSON object"]);
		return NO;
	}

	return MADCLIServeDispatch((NSDictionary *)object, documents);
}

MADCLIExitCode MADCLIRunServe(MADCLIInvocation *invocation) {
	(void)invocation;

	// The client and the engine share standard input/output as raw bytes; without
	// binary mode the Windows CRT would translate newlines on the protocol stream.
#if defined(_WIN32)
	_setmode(_fileno(stdin), _O_BINARY);
	_setmode(_fileno(stdout), _O_BINARY);
#endif

	NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents = [NSMutableDictionary dictionary];

	char *line = NULL;
	while ((line = MADCLIServeReadLine()) != NULL) {
		BOOL stop = NO;
		@autoreleasepool {
			stop = MADCLIServeHandleLine(line, documents);
		}
		free(line);
		line = NULL;
		if (stop) break;
	}

	// End-of-file or shutdown: leave nothing running behind the process.
	[documents removeAllObjects];
	return MADCLIExitSuccess;
}
