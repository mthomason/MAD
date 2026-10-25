//
//  MADDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDatabaseSqlite3_h
#define Reports_MADDatabaseSqlite3_h

#import <MADAPI/MADAliases.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseCacheProtocol.h>

BOOL Sqlite3StepResultOK(int result);

@class MADDatabaseDataBinding;

@interface MADDatabaseSqlite3 : MADDatabase <MADDatabaseCacheProtocol> {
  @public
	void * /* sqlite3 * */ _database;
}
- (void *)databaseHandle NS_RETURNS_INNER_POINTER;

- (NSString *)identifier;

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;

- (BOOL)bindStatement:(void ** /* sqlite3_stmt ** */)statement withBindings:(MADDatabaseDataBinding *)databinding;

- (void)openDatabase;
- (void)openDatabaseWithFlags:(int)flags;

int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);

+ (NSString *)sortDescriptionForColumnType:(MADDataType)columnType
								 ascending:(BOOL)ascending;

// The table is narrowed to the write port: the row loop below fills it with
// -removeAllObjects / -addColumn: / -addRowWithDataForFieldKeys: / -endBulkInsert
// and reads nothing back, so a caller can hand over any <MADDataTableWriting>.
- (BOOL)executeSQL: (NSString *)sql
		 fieldKeys: (NSArray *)fieldKeys
	  onConnection: (id)dbconn
   intoResultTable: (id <MADDataTableWriting>)dataTable
	transactionSet: (BOOL)partOfTransactionSet
	returnsResults: (BOOL)returnsResults
	binaryBindings: (NSArray *)binaryBindings
		 withError: (NSError * __autoreleasing *)resultError;

void mad_sqlite3Err(int rc, const char **errName, const char **errMsg);

+ (MADResult *)databaseResultValue:(void *)statement columnNumber:(int)columnNumber;
+ (MADResult *)databaseResultValueCast: (void * /* sqlite3_stmt * */)statement
					   forColumnNumber: (int)columnCounter
							  withType: (MADDataType)type;

+ (NSString *)sqlite3NativeType:(MADDataType)dataType;

/// Folds a SQLite database's write-ahead log into the main file, so the file alone is
/// complete.  Returns YES when the checkpoint completed and the WAL was reset; NO when
/// the database is still held open by another connection and the WAL could not be reset
/// (or when the file could not be opened at all).  Used by the document save path so a
/// reader that extracts only the store sees everything.
+ (BOOL)checkpointStoreAtURL:(NSURL *)storeURL;

@end

#endif
