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

#import "MNSDatabaseConnection.h"
#import "MNSDatabaseTable.h"
#import "MNSDatabaseField.h"

#import "RptqQueryFields.h"
#import "RptqQueryTables.h"

@interface MNSDatabaseMySql : MNSDatabase

- (id)initWithConnectionSettings: (MNSDatabaseConnection *)connectionSettings;

- (void)getTables: (void (^)(NSArray *tables))completion;

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion;

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

@end