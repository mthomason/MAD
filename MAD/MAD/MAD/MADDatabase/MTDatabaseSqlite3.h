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
#import <MADSqlite3/sqlite3.h>

@class MTDatabaseDataBinding;

typedef struct sqlite3_stmt sqlite3_stmt;
typedef NSString MADSqlite3SortDescription;

@interface MTDatabaseSqlite3 : MTDatabaseCache

    @property (nonatomic, readwrite, assign) sqlite3 *database;

    - (void *)databaseHandle;
    - (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

    - (NSString *)identifier;
    + (NSString *)identifier;

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (NSString *)safeIdentifier:(NSString *)fieldOrTableName;

    + (void)bindStatement:(sqlite3_stmt **)statement withBindings:(MTDatabaseDataBinding *)databinding;

    - (void)openDatabase;
    - (void)openDatabaseWithFlags:(int)flags;

    int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);
    int compare_string_utf8_localized_desc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);

    + (NSString *)newNativeTypeForDataType:(MTDataType)dataType;
    + (MADSqlite3SortDescription *)newSqlite3SortDescriptionForColumnType:(MTDataType)columnType
                                                                ascending:(BOOL)ascending;

    + (id)valueForStatement:(sqlite3_stmt *)statement columnNumber:(int)columnNumber;
    + (id)object:(sqlite3_stmt *)statement forColumnNumber:(int)columnCounter withType:(MTDataType)type;

    + (void)executeQueryWithSql:(NSString *)queryString
                       database:(sqlite3 *)_database
            queryBinaryBindings:(NSArray *)queryBinaryBindings
                 queryFieldKeys:(NSArray *)queryFieldKeys
      queryPartOfTransactionSet:(bool)queryPartOfTransactionSet;

@end

#endif
