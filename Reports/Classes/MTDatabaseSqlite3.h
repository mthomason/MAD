//
//  MTDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseSqlite3_h
#define Reports_MTDatabaseSqlite3_h

#import "MTDatabase.h"
#import "libSqlite3_8.h"

#import "MTDatabaseConnection.h"

@class MTDatabaseDataBinding;

@interface MTDatabaseSqlite3 : MTDatabase

- (void *)databaseHandle;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableName: (NSString *)tableName
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;


- (NSString *)identifier;
+ (NSString *)identifier;

+ (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;

+ (void)bindStatement:(sqlite3_stmt **)statement withBindings:(MTDatabaseDataBinding *)databinding andDatabase:(sqlite3 **)database;
- (void)bindStatement:(sqlite3_stmt **)statement withBindings:(MTDatabaseDataBinding *)databinding;

- (void)openDatabase;

int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);
int compare_string_utf8_localized_desc_collation(void* data, int len1, const void* arg1, int len, const void* arg2);

+ (NSString *)nativeTypeForDataType:(MTDataType)dataType;
+ (NSString *)sortDescForColumnType:(MTDataType)columnType ascending:(BOOL)ascending;

@end

#endif
