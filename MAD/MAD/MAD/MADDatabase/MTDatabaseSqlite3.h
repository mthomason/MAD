//
//  MTDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseSqlite3_h
#define Reports_MTDatabaseSqlite3_h

#import "MTDatabaseCache.h"

@class MTDatabaseDataBinding;

typedef NSString MADSqlite3SortDescription;

@interface MTDatabaseSqlite3 : MTDatabaseCache

    //@property (nonatomic, readwrite, assign) sqlite3 *database;

    - (void *)databaseHandle;
    - (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

    - (NSString *)identifier;
    + (NSString *)identifier;

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;

    + (void)bindStatement:(void ** /* sqlite3_stmt ** */)statement
             withBindings:(MTDatabaseDataBinding *)databinding;

    - (void)openDatabase;
    - (void)openDatabaseWithFlags:(int)flags;

    int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);
    int compare_string_utf8_localized_desc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);

    + (NSString *)newNativeTypeForDataType:(MADDataType)dataType;
    + (MADSqlite3SortDescription *)newSqlite3SortDescriptionForColumnType:(MADDataType)columnType
                                                                ascending:(BOOL)ascending;

    + (id)newValueForStatement:(void * /* sqlite3_stmt * */)statement
                  columnNumber:(int)columnNumber;
    + (id)newObject:(void * /* sqlite3_stmt * */)statement forColumnNumber:(int)columnCounter
           withType:(MADDataType)type;

    + (void)executeQueryWithSql:(NSString *)queryString
                       database:(void * /* sqlite3 * */)database
            queryBinaryBindings:(NSArray *)queryBinaryBindings
                 queryFieldKeys:(NSArray *)queryFieldKeys
      queryPartOfTransactionSet:(bool)queryPartOfTransactionSet;

@end

#endif
