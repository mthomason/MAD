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
#import "MTDatabaseTable.h"

typedef NS_ENUM(NSUInteger, MTDatabaseQueryType) {
	MTDatabaseQueryTypeNone = 0,
	MTDatabaseQueryTypeGetTables,
	MTDatabaseQueryTypeGetFields,
	MTDatabaseQueryTypeGetResults,
	MTDatabaseQueryTypeVerify
};

@interface MTDatabase : NSObject

+ (id)databaseObjectForRptqDatabase:(RptqDatabase *)database;
+ (id)databaseForRptqDatabase:(RptqDatabase *)database;

- (void)fieldsInDatabase: (NSString *)database andTable:(RptqTable *)table
              completion: (void (^)(MTDatabase *database, RptqTable *originTable, NSArray *fields))completion;

- (void)getTables: (void (^)(NSArray *tables))completion;

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion;

- (void)runQuery: (NSString *)query forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (NSString *)getSqlForQuery:(RptqQuery *)query;

- (NSString *)identifier;
+ (NSString *)identifier;

- (id)connectionSettings;

@end
