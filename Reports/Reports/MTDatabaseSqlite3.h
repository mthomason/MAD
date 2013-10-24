//
//  MTDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase.h"
//#import <liblibSqlite3_8/libSqlite3_8.h>
//#import "sqlite3.h"
#import "libSqlite3_8.h"

#import "MTDatabaseConnection.h"

@interface MTDatabaseSqlite3 : MTDatabase

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;

- (id)connectionSettings;

@end
