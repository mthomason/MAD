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

static void MADCLIServeQuery(NSDictionary *params, NSMutableDictionary <NSNumber *, MADCLIServeDocument *> *documents, id requestID) {
	MADCLIServeDocument *entry = MADCLIServeLookup(params, documents, requestID);
	if (entry == nil) return;

	id <MADDocumentDataProtocol> document = entry.document.document;
	NSError *error = nil;
	NSString *sql = [document.mainQuery copySQLWithManagedObjectContext: document.storeContext error: &error];
	if (sql == nil) {
		MADCLIServeWriteError(requestID, MADCLIExitQueryFailed, MADCLIDescriptionForError(error));
		return;
	}
	MADCLIServeWriteResult(requestID, @{ @"sql": sql });
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
