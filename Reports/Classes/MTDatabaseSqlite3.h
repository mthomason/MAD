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

- (void)openDatabase;

@end

#endif
