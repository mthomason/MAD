//
//  MTDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseSqlite3_h
#define Reports_MADDatabaseSqlite3_h

#import <Foundation/NSString.h>

#import <MADFoundation/MADDataType.h>

#import <MADAPI/MTDatabase.h>
#import <MADAPI/MADDatabaseCacheProtocol.h>

BOOL Sqlite3StepResultOK(int result);

@class MADDatabaseDataBinding;

typedef NSString MADSqlite3SortDescription;

@interface MTDatabaseSqlite3 : MTDatabase <MADDatabaseCacheProtocol> {
  @public
    void * /* sqlite3 * */ _database;
}
    - (void *)databaseHandle NS_RETURNS_INNER_POINTER;

    - (NSString *)identifier;

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    + (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
    - (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;

    - (BOOL)bindStatement:(void ** /* sqlite3_stmt ** */)statement
             withBindings:(MADDatabaseDataBinding *)databinding;

    - (void)openDatabase;
    - (void)openDatabaseWithFlags:(int)flags;

    int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);

    + (MADSqlite3SortDescription *)newSqlite3SortDescriptionForColumnType:(MADDataType)columnType
                                                                ascending:(BOOL)ascending;

    - (void)executeQueryWithSql:(NSString *)queryString
            queryBinaryBindings:(NSArray *)queryBinaryBindings
                 queryFieldKeys:(NSArray *)queryFieldKeys
                 transactionSet:(BOOL)partOfTransactionSet;

    - (BOOL)executeSQL: (NSString *)sql
             fieldKeys: (NSArray *)fieldKeys
          onConnection: (id)dbconn
       intoResultTable: (MADDataTable *)dataTable
        transactionSet: (BOOL)partOfTransactionSet
        returnsResults: (BOOL)returnsResults
        binaryBindings: (NSArray *)binaryBindings
             withError: (NSError * __autoreleasing *)resultError;

    void mad_sqlite3Err(int rc, const char **errName, const char **errMsg);

@end

@interface MADSqlite3NativeType : NSString

    + (instancetype)newSqlite3NativeType:(MADDataType)dataType;

@end

@interface MADDatabaseResultValue : NSObject <NSCopying>

    + (instancetype)newDatabaseResultValue:(void *)statement columnNumber:(int)columnNumber;
    + (instancetype)newDatabaseResultValueCast: (void * /* sqlite3_stmt * */)statement
                               forColumnNumber: (int)columnCounter
                                      withType: (MADDataType)type;

@end

#endif
