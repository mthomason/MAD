//
//  MNSDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabase_h
#define Reports_MTDatabase_h

#import <Foundation/Foundation.h>
#import "RptqDatabaseSchemaTable.h"
#import "RptqQuery+Extras.h"
#import "MTDatabaseTable.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

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

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

- (NSString *)getSqlForQuery:(RptqQuery *)query;

- (NSString *)identifier;
+ (NSString *)identifier;

- (id)connectionSettings;

- (NSString *)selectPart;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
