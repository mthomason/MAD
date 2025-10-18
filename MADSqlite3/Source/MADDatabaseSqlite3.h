//
//  MADDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDatabaseSqlite3_h
#define Reports_MADDatabaseSqlite3_h

#import <MADAPI/MADAliases.h>
#import <MADFoundation/MADDataType.h>

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

- (BOOL)executeSQL: (NSString *)sql
		 fieldKeys: (NSArray *)fieldKeys
	  onConnection: (id)dbconn
   intoResultTable: (MADDataTable *)dataTable
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

@end

#endif
