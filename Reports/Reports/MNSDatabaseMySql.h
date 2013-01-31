//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabase.h"
#import <MySqlClientObjectiveC/MysqlConnection.h>
#import <MySqlClientObjectiveC/MysqlServer.h>
#import <MySqlClientObjectiveC/MysqlFetch.h>
#import <MySqlClientObjectiveC/MysqlFetchField.h>

#import "MTGraph.h"

#import "MNSDatabaseConnection.h"
#import "MNSDatabaseTable.h"
#import "MNSDatabaseField.h"

#import "RptqQueryCache+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqTable+Extras.h"
#import "RptqField+Extras.h"
#import "RptqQueryResultFields+Extras.h"
#import "RptqQueryResultValues+Extras.h"
#import "RptqQueryResult+Extras.h"

@interface MNSDatabaseMySql : MNSDatabase

- (id)initWithConnectionSettings: (MNSDatabaseConnection *)connectionSettings;

- (void)getTables: (void (^)(NSArray *tables))completion;

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion;

- (void)runQuery: (NSString *)query forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MNSDatabase *database, RptqQueryCache *cache))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

- (id)connectionSettings;

@end