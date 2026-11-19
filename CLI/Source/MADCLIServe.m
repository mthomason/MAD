//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIServe.m
//  MAD Designer
//
//  `mad serve` -- the long-lived process boundary the Windows shell speaks (the
//  WPF app's engine; docs/project/MAD_WINDOWS.md §Phase 4).  It reads newline-delimited
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

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADReportExporting.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExportSource.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataType.h>

#import <MAD/MADDatabase+Constructor.h>
#import <MADAPI/MADDatabase.h>
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
static NSArray <NSDictionary *> *MADCLIServeColumns(id <MADDocumentDataProtocol> document) {
	NSError *error = nil;
	MADReportExportSource *source = [MADReportExportSource sourceWithDocument: document error: &error];
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

/// The stored database schema, the same tables/fields `mad schema` prints, as JSON.
static NSArray <NSDictionary *> *MADCLIServeTables(id <MADDocumentDataProtocol> document) {
	RptqDocument *model = document.activeDocumentModel;
	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
	NSMutableArray <NSDictionary *> *tables = [NSMutableArray array];

	for (RptqDatabase *schema in model.hasDatabaseSchemas) {
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
	}
	return tables;
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
	if ([document isKindOfClass: [MADHeadlessDocument class]]) {
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

static void MADCLIServeDescribe(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	MADCLIServeWriteResult(requestID, @{
		@"driver": MADCLIServeDriverName(document),
		@"columns": MADCLIServeColumns(document),
		@"tables": MADCLIServeTables(document),
	});
}

/// The generated SQL, the way the Mac's Query workspace shows it: all fields first
/// (-SQLOnlyActiveFields:NO), falling back to the active-field select when the query has no
/// report elements to reference -- so a fresh document still yields SQL.
static NSString *MADCLIServeGeneratedSQL(id <MADDocumentDataProtocol> document) {
	NSError *error = nil;
	NSString *generated = [document.mainQuery SQLOnlyActiveFields: NO
											managedObjectContext: document.storeContext
														   error: &error];
	if (generated.length == 0) {
		generated = [document.mainQuery copySQLWithManagedObjectContext: document.storeContext error: &error];
	}
	return generated ?: @"";
}

static void MADCLIServeQuery(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	MADCLIServeWriteResult(requestID, @{ @"sql": MADCLIServeGeneratedSQL(document) });
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

	NSDate *started = [NSDate date];
	if (![entry.document refreshWithCredentials: credentials error: &error]) {
		MADCLIServeWriteError(requestID, MADCLIExitQueryFailed, MADCLIDescriptionForError(error));
		return;
	}
	NSTimeInterval elapsed = -[started timeIntervalSinceNow];

	MADCLIServeWriteResult(requestID, @{
		@"rowCount": @(document.numberOfResults),
		@"elapsed": @(elapsed),
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
	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	if (![exporter exportDocument: entry.document.document
							toURL: outURL
						  options: deterministic ? MADReportExportOptionsDeterministic : MADReportExportOptionsNone
							error: &error]) {
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
static NSDictionary *MADCLIServeQueryModelDict(id <MADDocumentDataProtocol> document) {
	RptqStoreContext *context = document.storeContext;
	RptqQuery *query = MADCLIServeMainQuery(document);

	NSString *driver = @"";
	if (document.database.databaseConnection != nil) {
		driver = MADCLIServeTokenForDatabaseType(document.database.databaseConnection.databaseType);
	}

	NSString *sql = MADCLIServeGeneratedSQL(document);

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
			}];
		}
		[fields sortUsingDescriptors: @[byName]];
		[tables addObject: @{
			@"id": @(table.identifier),
			@"name": table.databaseSchemaTable.name ?: @"",
			@"alias": table.alias ?: @"",
			@"dropIndex": @(table.dropIndex),
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
	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(entry.document.document));
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
	RptqDatabase *database = [RptqDocument newDocumentReadFromManagedObjectContext: context].defaultDatabase;
	RptqQuery *query = database.defaultQuery;

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
																	 database: database
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

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQuery *query = MADCLIServeMainQuery(document);

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

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQuery *query = MADCLIServeMainQuery(document);

	RptqQueryField *left = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: leftID];
	RptqQueryField *right = (RptqQueryField *)[context objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: rightID];
	if (left == nil || right == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"unknown query field.");
		return;
	}
	if (left.inQueryTable.identifier == right.inQueryTable.identifier) {
		MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document)); // no-op, like the Mac
		return;
	}

	for (RptqQueryLinks *existing in query.hasQueryLinks) {
		if ((existing.hasLeftField.identifier == leftID && existing.hasRightField.identifier == rightID) ||
			(existing.hasLeftField.identifier == rightID && existing.hasRightField.identifier == leftID)) {
			MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document)); // already linked
			return;
		}
	}

	RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField: left
														   rightField: right
															 joinType: MADLinkTypeLeftOuterJoin
												 managedObjectContext: context];
	[query addHasQueryLinksObject: link];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQueryLinks *link = (RptqQueryLinks *)[document.storeContext objectForEntity: NSStringFromClass([RptqQueryLinks class]) identifier: linkID];
	if (link == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown query link %lld.", linkID]);
		return;
	}
	link.type = (int16_t)[params[@"type"] integerValue];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQuery *query = MADCLIServeMainQuery(document);
	RptqQueryLinks *link = (RptqQueryLinks *)[context objectForEntity: NSStringFromClass([RptqQueryLinks class]) identifier: linkID];
	if (link != nil) {
		[query removeHasQueryLinksObject: link];
		[context deleteObject: link error: NULL];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQueryPredicate *predicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: leftID
																			comparsonOperator: (MADPredicateOperator)[params[@"operator"] integerValue]
																				andRightValue: value
																  forManagedObjectContext: document.storeContext
																						error: &error];
	if (predicate == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, MADCLIDescriptionForError(error));
		return;
	}
	[MADCLIServeMainQuery(document) addHasQueryPredicateObject: predicate];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	RptqQuery *query = MADCLIServeMainQuery(document);
	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context objectForEntity: NSStringFromClass([RptqQueryPredicate class]) identifier: predicateID];
	if (predicate != nil) {
		[query removeHasQueryPredicateObject: predicate];
		[context deleteObject: predicate error: NULL];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	id <MADSQLQueryDocument> qdoc = MADCLIServeQueryDocument(document);
	if (qdoc == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"the document cannot edit its query.");
		return;
	}

	MADSortOrder sort = ([params[@"sort"] isKindOfClass: [NSNumber class]] && [params[@"sort"] integerValue] == 1)
		? MADSortOrderDecending : MADSortOrderAccending;
	[qdoc addQueryGroupWithQueryField: fieldID andSortOrder: sort];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
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
	[qdoc removeGroupWitObjectID: groupID fromManagedObjectContext: document.storeContext];

	MADCLIServeWriteResult(requestID, MADCLIServeQueryModelDict(document));
}

#pragma mark - SQL entry (Phase 6b)

/// Parses `sql` and resolves it against the document's schema (and, when `apply`, runs the
/// compiler).  Returns the plan, or nil with `outError` -- the same MADSQLParser →
/// MADSQLStatementResolver → MADSQLQueryCompiler path the Mac's SQL editor takes.
static MADSQLQueryPlan *MADCLIServeCompileSQL(id <MADDocumentDataProtocol> document, NSString *sql, BOOL apply, NSError **outError) {
	RptqStoreContext *context = document.storeContext;
	RptqDatabase *database = [RptqDocument newDocumentReadFromManagedObjectContext: context].defaultDatabase;

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
																			 query: database.defaultQuery
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

	NSError *compileError = nil;
	MADSQLQueryPlan *plan = MADCLIServeCompileSQL(entry.document.document, sql, NO, &compileError);
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

	NSError *compileError = nil;
	MADSQLQueryPlan *plan = MADCLIServeCompileSQL(entry.document.document, sql, YES, &compileError);
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
static NSArray <RptqDocumentSection *> *MADCLIServeOrderedSections(id <MADDocumentDataProtocol> document) {
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];
	NSMutableArray <RptqDocumentSection *> *sections = [NSMutableArray array];
	if (doc.hasReportHeaderSection) [sections addObject: doc.hasReportHeaderSection];
	if (doc.hasPageHeaderSection) [sections addObject: doc.hasPageHeaderSection];

	RptqQuery *query = doc.defaultDatabase.defaultQuery;
	NSArray <RptqQueryGroup *> *groups = [query sortedQueryGroups] ?: @[];
	for (RptqQueryGroup *group in groups) {
		RptqDocumentSection *header = [RptqDocumentSection headerSectionInSections: group.hasSection];
		if (header) [sections addObject: header];
	}
	if (doc.hasDetailSection) [sections addObject: doc.hasDetailSection];
	for (RptqQueryGroup *group in [groups reverseObjectEnumerator]) {
		RptqDocumentSection *footer = [RptqDocumentSection footerSectionInSections: group.hasSection];
		if (footer) [sections addObject: footer];
	}
	if (doc.hasPageFooterSection) [sections addObject: doc.hasPageFooterSection];
	if (doc.hasReportFooterSection) [sections addObject: doc.hasReportFooterSection];
	return sections;
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

static RptqDocumentSection *MADCLIServeSectionForElement(id <MADDocumentDataProtocol> document, RptqDocumentElement *element) {
	if (element.inSectionRow && element.inSectionRow.inSection) return element.inSectionRow.inSection;
	for (RptqDocumentSection *section in MADCLIServeOrderedSections(document)) {
		for (RptqDocumentSectionRows *row in section.hasRows) {
			if ([row.hasObjects containsObject: element]) return section;
		}
	}
	return nil;
}

static RptqQueryField *MADCLIServeFirstQueryField(id <MADDocumentDataProtocol> document) {
	RptqQuery *query = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext].defaultDatabase.defaultQuery;
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

	if ([element isKindOfClass: [RptqDocumentElementLabel class]]) {
		text = ((RptqDocumentElementLabel *)element).text ?: @"";
	} else if ([element isKindOfClass: [RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)element;
		text = df.text ?: @"";
		tableID = df.tableID ?: @"";
		columnID = df.fieldID ?: @"";
		if (df.referencesQueryField) fieldID = df.referencesQueryField.identifier;
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

	return @{
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
	};
}

static NSDictionary *MADCLIServeLayoutModelDict(id <MADDocumentDataProtocol> document) {
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext];

	NSMutableArray <NSDictionary *> *sections = [NSMutableArray array];
	NSMutableArray <NSDictionary *> *elements = [NSMutableArray array];
	for (RptqDocumentSection *section in MADCLIServeOrderedSections(document)) {
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
	RptqQuery *query = doc.defaultDatabase.defaultQuery;
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
	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(entry.document.document));
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
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *section = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: sectionID];
	if (section == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", sectionID]);
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
		RptqQueryField *bound = MADCLIServeFirstQueryField(document);
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
		agg.aggregateField = MADCLIServeFirstQueryField(document);
		w = 144.0; h = 22.0;
		element = agg;
	} else if ([kind isEqualToString: @"image"]) {
		RptqDocumentElementImage *img = (RptqDocumentElementImage *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementImage class]) identifier: 0];
		img.type = (int16_t)MADPrintPageElementTypeImage;
		w = 96.0; h = 64.0;
		element = img;
	} else if ([kind isEqualToString: @"line"]) {
		RptqDocumentElementLabel *line = (RptqDocumentElementLabel *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementLabel class]) identifier: 0];
		line.type = (int16_t)MADPrintPageElementTypeLabelStatic;
		line.text = @"";
		if (line.border && line.border.width) line.border.width.bottom = 1.5f;
		w = 320.0; h = 8.0;
		element = line;
	} else {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown element kind '%@'.", kind]);
		return;
	}

	[element setSizeWidth: (float)w height: (float)h];
	[section addDocumentObject: element withDropPoint: CGPointMake(x, y) managedObjectContext: context];
	MADCLIServeSetElementOrigin(element, x, y);
	element.inSectionRow = section.hasRows.firstObject;
	MADCLIServeGrowSectionForElement(section, element);

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
}

static void MADCLIServeRemoveElements(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	if (![params[@"elements"] isKindOfClass: [NSArray class]]) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, @"elements must be an array.");
		return;
	}

	id <MADDocumentDataProtocol> document = entry.document.document;
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in params[@"elements"]) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		for (RptqDocumentSection *section in MADCLIServeOrderedSections(document)) {
			for (RptqDocumentSectionRows *row in section.hasRows) {
				if ([row.hasObjects containsObject: element]) {
					[row removeHasObjectsObject: element];
				}
			}
		}
		element.inSectionRow = nil;
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *target = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: targetSectionID];
	if (target == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", targetSectionID]);
		return;
	}
	MADCLIServeEnsureFirstRow(target, context);
	RptqDocumentSectionRows *targetRow = target.hasRows.firstObject;

	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		for (RptqDocumentSection *section in MADCLIServeOrderedSections(document)) {
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

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	for (NSDictionary *item in array) {
		if (![item isKindOfClass: [NSDictionary class]]) continue;
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [item[@"id"] longLongValue]];
		if (element == nil) continue;
		double x = [item[@"x"] isKindOfClass: [NSNumber class]] ? [item[@"x"] doubleValue] : 0.0;
		double y = [item[@"y"] isKindOfClass: [NSNumber class]] ? [item[@"y"] doubleValue] : 0.0;
		double w = [item[@"w"] isKindOfClass: [NSNumber class]] ? [item[@"w"] doubleValue] : 0.0;
		double h = [item[@"h"] isKindOfClass: [NSNumber class]] ? [item[@"h"] doubleValue] : 0.0;
		MADCLIServeSetElementOrigin(element, x, y);
		[element setSizeWidth: (float)w height: (float)h];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: elementID];
	if (element == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown element %lld.", elementID]);
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
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
		if ([params[@"fontname"] isKindOfClass: [NSString class]]) element.fontname = params[@"fontname"];
		if ([params[@"fontsize"] isKindOfClass: [NSNumber class]]) element.fontsize = [params[@"fontsize"] doubleValue];
		if ([params[@"bold"] isKindOfClass: [NSNumber class]]) element.textStyle.bold = [params[@"bold"] boolValue];
		if ([params[@"italic"] isKindOfClass: [NSNumber class]]) element.textStyle.italic = [params[@"italic"] boolValue];
		if ([params[@"underline"] isKindOfClass: [NSNumber class]]) element.textStyle.underline = [params[@"underline"] boolValue];
		if ([params[@"strikethrough"] isKindOfClass: [NSNumber class]]) element.textStyle.strikethrough = [params[@"strikethrough"] boolValue];
		if ([params[@"hAlign"] isKindOfClass: [NSNumber class]]) element.alignment.horizontal = (int16_t)[params[@"hAlign"] integerValue];
		if ([params[@"vAlign"] isKindOfClass: [NSNumber class]]) element.alignment.vertical = (int16_t)[params[@"vAlign"] integerValue];
	}

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *element = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (element == nil) continue;
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

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
	RptqStoreContext *context = document.storeContext;
	RptqDocumentSection *section = (RptqDocumentSection *)[context objectForEntity: NSStringFromClass([RptqDocumentSection class]) identifier: sectionID];
	if (section == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitUsage, [NSString stringWithFormat: @"unknown section %lld.", sectionID]);
		return;
	}
	if ([params[@"height"] isKindOfClass: [NSNumber class]]) [section setInterfaceHeight: [params[@"height"] doubleValue]];
	if ([params[@"visible"] isKindOfClass: [NSNumber class]]) section.visibility = [params[@"visible"] boolValue];
	if ([params[@"pageBreak"] isKindOfClass: [NSNumber class]]) [section setProducesFormFeed: [params[@"pageBreak"] boolValue]];

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
		RptqDocumentElementImage *dup = (RptqDocumentElementImage *)[context insertObjectForEntity: NSStringFromClass([RptqDocumentElementImage class]) identifier: 0];
		dup.type = src.type;
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
	RptqStoreContext *context = document.storeContext;
	for (NSNumber *idNumber in ids) {
		RptqDocumentElement *src = (RptqDocumentElement *)[context objectForEntity: NSStringFromClass([RptqDocumentElement class]) identifier: [idNumber longLongValue]];
		if (src == nil) continue;
		RptqDocumentSection *section = MADCLIServeSectionForElement(document, src);
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

	MADCLIServeWriteResult(requestID, MADCLIServeLayoutModelDict(document));
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
		if ([method isEqualToString: MADCLIServeMethodOpen]) {
			MADCLIServeOpen(params, documents, requestID);
		} else if ([method isEqualToString: MADCLIServeMethodCreate]) {
			MADCLIServeCreate(params, documents, requestID);
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
