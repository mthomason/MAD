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

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;


- (NSString *)identifier;
+ (NSString *)identifier;

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;

- (void)openDatabase;

@end

#endif
