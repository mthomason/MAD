//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
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
#import "RptqTable+Extras.h"
#import "RptqField+Extras.h"
#import "RptqQueryResultFields+Extras.h"
#import "RptqQueryResultValues+Extras.h"
#import "RptqQueryResult+Extras.h"

@interface MTDatabaseMySql : MTDatabase

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)runQuery: (NSString *)query forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

- (id)connectionSettings;

@end

#endif
