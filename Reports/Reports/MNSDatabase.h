//
//  MNSDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RptqTable.h"
#import "RptqQuery+Extras.h"
#import "MNSDatabaseTable.h"

typedef NS_ENUM(NSUInteger, NSDatabaseQueryType) {
	NSDatabaseQueryTypeNone = 0,
	NSDatabaseQueryTypeGetTables,
	NSDatabaseQueryTypeGetFields,
	NSDatabaseQueryTypeGetResults,
	NSDatabaseQueryTypeVerify
};

//extern NSString * const KEY_DB_TYPE_NONE;

@interface MNSDatabase : NSObject

+ (id)databaseObjectForRptqDatabase:(RptqDatabase *)database;

- (void)fieldsInDatabase: (NSString *)database andTable:(RptqTable *)table
              completion: (void (^)(MNSDatabase *database, RptqTable *originTable, NSArray *fields))completion;

- (void)getTables: (void (^)(NSArray *tables))completion;

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion;

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion;

- (NSString *)getSqlForQuery:(RptqQuery *)query;

- (NSString *)identifier;
+ (NSString *)identifier;

@end