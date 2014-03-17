//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseMySql_h
#define Reports_MTDatabaseMySql_h

#import "MTDatabase.h"
#import <MySqlClientObjectiveC/MysqlConnection.h>
#import <MySqlClientObjectiveC/MysqlServer.h>
#import <MySqlClientObjectiveC/MysqlFetch.h>
#import <MySqlClientObjectiveC/MysqlFetchField.h>

#import "MTGraph.h"

#import "MTDatabaseConnection.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "RptqQueryCache+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryPredicate+Extras.h"
#import "MTKeyChain.h"

@interface MTDatabaseMySql : MTDatabase

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

#endif
