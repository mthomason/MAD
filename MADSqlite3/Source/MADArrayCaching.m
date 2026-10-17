//
//  MTArrayCached.m
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADArrayCaching.h"

#import "MADDatabaseConnectionSqlite3.h"
#import "MADQueryCacheAddColumn.h"

#import <MADSqlite3/sqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADQueryCacheDeleteAllFromTable.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADDataStructures/MADIndex.h>
#import <MADSqlite3/MADQueryCacheSelectLimitOffsetParamaters.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSData.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSError.h>
#import <dispatch/dispatch.h>
#import <MADFoundation/madlog.h>

static os_log_t caching_log;
NSString * const MTArrayCachedTableName = @"ac";
NSString * const MTArrayCachedColumnKey = @"ci";
NSString * const MTArrayCachedColumnValue = @"ck";
NSString * const MTArrayCachedExtension = @"madac";

typedef NS_ENUM(short, MADObjectInitalized) {
	MADObjectInitalizedYes = 2,
	MADObjectInitalizedNo = 3,
	MADObjectInitalizedNotSets = 4,
};

#ifdef MAD_MTArrayCached_DEBUG
void sqliteCallbackFunc(void *foo, const char* statement);
void sqliteCallbackFunc(void *foo, const char* statement) {
	MTLogStatic(@"=> %s", statement);
}
#endif

@interface MADArrayCaching ()

	@property (nonatomic, strong, readwrite) MADDatabaseSqlite3 *database;
	@property (nonatomic, retain) NSSet <Class> *types;

	@property (nonatomic, copy, readwrite) NSString *identifier;
#if __APPLE__
	@property (nonatomic, copy, readwrite) dispatch_queue_t archivingQueue;
	@property (nonatomic, copy, readwrite) dispatch_queue_t unarchiveQueue;
#else
	// Dispatch objects are plain C pointers off Apple (os/object.h declines
	// ObjC support outside Darwin), so ARC cannot own one.
	@property (nonatomic, assign, readwrite) dispatch_queue_t archivingQueue;
	@property (nonatomic, assign, readwrite) dispatch_queue_t unarchiveQueue;
#endif

	@property (nonatomic, strong, readwrite) MADIndex *lastObjectSelected;

	@property (nonatomic, copy, readonly) NSURL *url;
	@property (nonatomic, readwrite, assign) MADArrayCachingState state;

@end

@implementation MADArrayCaching {
	MADObjectInitalized _hasNumberOfRows;
	long long _numberOfRows;
	NSURL *_url;
	sqlite3_stmt *_statementInsert;
	sqlite3_stmt *_statementSelect;
	sqlite3_stmt *_statementCount;
	// Elements unarchived on first read, keyed by index, so a repeated read does not
	// pay the SQLite round-trip and the unarchive again.  NSNull marks "read, but nil".
	NSMutableDictionary <NSNumber *, id> *_cachedElements;
}

@dynamic url;

+ (void)initialize {
	if (self == [MADArrayCaching self]) {
		NSString *name = NSStringFromClass([MADArrayCaching class]);
		caching_log = os_log_create("com.mad", name.UTF8String);
	}
}

- (void)dealloc {
	_lastObjectSelected = nil;
	if (_statementInsert != NULL) {
		sqlite3_finalize(_statementInsert);
		sqlite3_finalize(_statementSelect);
		sqlite3_finalize(_statementCount);
		_statementCount = NULL;
		_statementInsert = NULL;
		_statementSelect = NULL;
	}
	//sqlite3_close_v2(_database.databaseHandle);
}

- (void)finalizeDatabase {
	sqlite3_finalize(_statementInsert);
	sqlite3_finalize(_statementSelect);
	sqlite3_finalize(_statementCount);
	_statementCount = NULL;
	_statementInsert = NULL;
	_statementSelect = NULL;
	//sqlite3_close_v2(_database.databaseHandle);
}

- (instancetype _Nonnull)initWithIdentifier:(nonnull NSString *)identifier
							 cachedDelegate:(nonnull id <MADCacheProtocol>)cachedDelegate
									  types:(nonnull NSSet<Class> *)classes {
	// The identifier becomes the on-disk file name; an empty one cannot build
	// a URL and was the reachable nil case in -url.
	NSParameterAssert(identifier.length > 0);
	if (self = [super init]) {
		
		NSSet <Class> *types = [[NSSet alloc] initWithSet:classes];
		self.types = types;
		
		_state = MADArrayCachingStateInital;
		_hasNumberOfRows = MADObjectInitalizedNotSets;
		_numberOfRows = 0;
		
		NSAssert(cachedDelegate != nil, @"We need delegate to get cache location.");
		
		_archivingQueue = dispatch_queue_create("MADArrayCachingQueue", DISPATCH_QUEUE_SERIAL);
		_unarchiveQueue = dispatch_queue_create("MADArrayCachingQueueReader", DISPATCH_QUEUE_SERIAL);
		_statementCount = NULL;
		_statementInsert = NULL;
		_statementSelect = NULL;
		
		_identifier = [identifier copy];
		_cachedDelegate = cachedDelegate;
		_cachedElements = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)reopenDatabaseAtUrl:(NSURL *)url {
	MADDatabaseConnection *databaseConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	[database setDatabaseConnection:databaseConnection];
	[database openDatabase];

#ifdef MAD_MTArrayCached_DEBUG
	sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
	
	self.database = database;
}

- (void)initializeDatabase {
	self.state = MADArrayCachingStateLoading;
	NSURL *url = [self url];
	[self reopenDatabaseAtUrl:url];
	if (![self.database tableExist:MTArrayCachedTableName]) {

		MADDataColumn *columnKey = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnKey];
		columnKey.type = MADDataTypeInteger;
		columnKey.primaryKey = YES;
		columnKey.notNull = YES;
		columnKey.autoIncrement = NO;
		
		[self addColumn: columnKey toTable:MTArrayCachedTableName
			 columnName: columnKey.identifier
			createTable: YES
				 unique: NO];

		MADDataColumn *columnValue = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnValue];
		columnValue.type = MADDataTypeBlob;
		columnValue.primaryKey = NO;
		columnValue.notNull = YES;
		columnValue.autoIncrement = NO;

		[self addColumn: columnValue
				toTable: MTArrayCachedTableName
			 columnName: columnValue.identifier
			createTable: NO
				 unique: NO];

		_numberOfRows = 0;
		self.state = MADArrayCachingStateEmpty;
	} else {
		self.state = MADArrayCachingStateLoaded;
	}
	[self prepareStatements];
	_numberOfRows = 0;
	_hasNumberOfRows = MADObjectInitalizedNo;
}

- (void)beginBulkInserts {
	[self.database beginBulkInsert];
}

- (void)endBulkInserts {
	[self.database endBulkInsert];
	NSURL *url = [self url];
	[self reopenDatabaseAtUrl: url];
	[self prepareStatements];

}

- (BOOL)prepareStatements {
	return [self prepareStatementInsert] &&
		[self prepareStatementSelect] &&
		[self prepareStatementCount];
}

- (BOOL)prepareStatementInsert {
	NSString *queryString = [[NSString alloc] initWithFormat: @"INSERT INTO %@ (%@, %@) VALUES (?1, ?2);",
															  MTArrayCachedTableName,
															  MTArrayCachedColumnKey,
															  MTArrayCachedColumnValue];
	if (_statementInsert != NULL) {
		sqlite3_finalize(_statementInsert);
		_statementInsert = NULL;
	}
	__block BOOL success = YES;
	if (_statementInsert == NULL) {
		MADDatabaseSqlite3 *database = self.database;
		__block sqlite3_stmt *stmt_insert = _statementInsert;
		dispatch_sync(self.archivingQueue, ^{
			@autoreleasepool {
				
				int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1, &stmt_insert, NULL);
				NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
				success = prepare_result == SQLITE_OK;
			}
		});
		_statementInsert = stmt_insert;
	}
	return success;
}

- (BOOL)prepareStatementSelect {
	NSString *queryString = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1  OFFSET 0;",
															  MTArrayCachedColumnValue,
															  MTArrayCachedTableName,
															  MTArrayCachedColumnKey];
	if (_statementSelect != NULL) {
		sqlite3_finalize(_statementSelect);
		_statementSelect = NULL;
	}
	BOOL success = YES;
	if (_statementSelect == NULL) {
		MADDatabaseSqlite3 *database = self.database;
		int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1,
									 &_statementSelect, NULL);
		NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
		success = prepare_result == SQLITE_OK;
	}
	return success;

}

- (BOOL)prepareStatementCount {
	NSString *queryString = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT 1 OFFSET 0;",
															  MTArrayCachedColumnKey,
															  MTArrayCachedTableName,
															  MTArrayCachedColumnKey];
	if (_statementCount != NULL) {
		sqlite3_finalize(_statementCount);
		_statementCount = NULL;
	}
	BOOL success = YES;
	if (_statementCount == NULL) {
		MADDatabaseSqlite3 *database = self.database;
		int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1, &_statementCount, NULL);
		NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
		success = prepare_result == SQLITE_OK;
	}
	return success;
}

- (NSURL *)url {
	NSURL *cachedArrayDirectories = [self.cachedDelegate cachedFilesDirectory];
	NSString *fileName = [self.identifier stringByAppendingPathExtension:@"madac"];
	if (fileName == nil) return nil;
	_url = [cachedArrayDirectories URLByAppendingPathComponent:fileName isDirectory:NO];
	return _url;
}

- (void)addColumn:(MADDataColumn *)column
		  toTable:(NSString *)table
	   columnName:(NSString *)columnName
	  createTable:(BOOL)create
		   unique:(BOOL)unique {
	NSString *columnAffinity = [MADDatabaseSqlite3 sqlite3NativeType:column.type];
	MADQueryCacheAddColumn *queryCacheAddColumn = [[MADQueryCacheAddColumn alloc] initWithTableName: table
																						 columnName: columnName
																							 column: column
																						createTable: create
																				   uniqueColumnHack: unique
																					 columnAffinity: columnAffinity];
	NSError *error = NULL;
	BOOL success = [self.database executeQuery:queryCacheAddColumn withError:&error];
	if (error != nil) {
		os_log_error(caching_log, "Error: %@", error);
	}
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_database->_database), __PRETTY_FUNCTION__);
}

- (void)addObject:(id _Nonnull)object {
	_lastObjectSelected = nil;
	NSAssert(object != nil, @"Need an object.");
	long long numberOfRows = _numberOfRows;
	sqlite3_stmt *statementInsert = _statementInsert;
	id objectToAdd = object;
	dispatch_sync(self.archivingQueue, ^{
		//NSData *data = [NSKeyedArchiver archivedDataWithRootObject:objectToAdd];
		NSError *error = nil;
#if __APPLE__
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:objectToAdd requiringSecureCoding:YES error:&error];
#else
		// GNUstep has no secure coding: the strict archive is nil and the cache
		// could store nothing.  The permissive archive is the same coder without
		// the hardening, which is what the .madac cache needs to function off
		// Apple (the toolchain probe records the gap).
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:objectToAdd requiringSecureCoding:NO error:&error];
#endif
		if (error != nil) {
			os_log_error(caching_log, "NSKeyedArchiver Error: %@", error.localizedDescription);
		}
		int bind_result = sqlite3_bind_int(statementInsert, 1, (int)numberOfRows);
		NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
		bind_result = sqlite3_bind_blob(statementInsert, 2, data.bytes, (int)data.length, SQLITE_STATIC);
		NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
		bind_result = sqlite3_step(statementInsert);
		NSAssert((bind_result == SQLITE_OK) || (bind_result == SQLITE_ROW) || (bind_result == SQLITE_DONE), @"Error: '%s'.", __PRETTY_FUNCTION__);
		if (bind_result == SQLITE_DONE) {
			sqlite3_reset(statementInsert);
			sqlite3_clear_bindings(statementInsert);
		}
	});
	_hasNumberOfRows = MADObjectInitalizedYes;
	++_numberOfRows;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index { return [self objectAtIndex: index]; }

- (id)objectAtIndex:(NSUInteger)index {

	// The render cache is read many times a second during layout, and the disk read
	// plus the unarchive dominate each access.  Serve every element from memory after
	// its first read; NSNull marks an element that was read and came back nil.
	NSNumber *key = @(index);
	id cached = _cachedElements[key];
	if (cached != nil) {
		return cached == (id)[NSNull null] ? nil : cached;
	}

	__block id result = nil;
	sqlite3_stmt *statementSelect = _statementSelect;
	dispatch_sync(self.unarchiveQueue, ^{
		sqlite3_bind_int(statementSelect, 1, (int)index);

		if (sqlite3_step(statementSelect) == SQLITE_ROW) {
			const void *blob = sqlite3_column_blob(statementSelect, 0);
			int bytes = sqlite3_column_bytes(statementSelect, 0);
			NSData *queryResult = [[NSData alloc] initWithBytes: blob
														 length: (NSUInteger)bytes];
			NSError *error = nil;
			result = [NSKeyedUnarchiver unarchivedObjectOfClasses:self.types fromData:queryResult error:&error];
			if (error != nil) {
				os_log_error(caching_log, "NSKeyedArchiver Error: %@", error.localizedDescription);
			}
		}
		sqlite3_clear_bindings(statementSelect);
		sqlite3_reset(statementSelect);
	});

	_cachedElements[key] = result ?: (id)[NSNull null];

	MADIndex *idx = [[MADIndex alloc] initWithIndex:index andObject:result];
	self.lastObjectSelected = idx;

	return result;
}

- (id)nextObject {
	return _lastObjectSelected ? [self objectAtIndex: _lastObjectSelected.index + 1] :
								 [self objectAtIndex: 0];
}

- (BOOL)removeAllObjects {
	_lastObjectSelected = nil;
	_numberOfRows = 0;
	_hasNumberOfRows = MADObjectInitalizedNotSets;
	[_cachedElements removeAllObjects];
	MADQuery *query = [[MADQueryCacheDeleteAllFromTable alloc] initWithTableName:MTArrayCachedTableName];
	NSError *error = nil;
	BOOL result = [self.database executeQuery:query withError:&error];
	if (error != nil) {
		os_log_error(caching_log, "Error: %@", error);
	}
	return result;
}

- (NSUInteger)count {
	if (_hasNumberOfRows != MADObjectInitalizedYes) {
		sqlite_int64 count = 0;
		sqlite3_stmt *stmt_count = _statementCount;

		int stepResult = sqlite3_step(stmt_count);
		if (stepResult == SQLITE_ROW) {
			// ci is the element index (0-based), so the count is the largest index plus
			// one.  An empty table returns SQLITE_DONE and has a count of zero.
			count = sqlite3_column_int64(stmt_count, 0) + 1;
			sqlite3_reset(stmt_count);
		} else {
			count = 0;
		}
		_hasNumberOfRows = MADObjectInitalizedYes;
		_numberOfRows = count;
	}
	return (NSUInteger)_numberOfRows;
}

- (BOOL)isEmpty { return _numberOfRows == 0; }

@end
