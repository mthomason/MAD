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
#import "RptqQueryField.h"

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

- (NSString *)safeQueryField:(RptqQueryField *)queryField;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)cacheReportQueryForDocument:(RptqDocument *)document
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

- (NSString *)getSqlForQuery:(RptqQuery *)query;
- (NSString *)getSqlForQuery:(RptqQuery *)query onlyActiveFields:(BOOL)onlyActiveFields;

- (NSString *)identifier;
+ (NSString *)identifier;

- (NSString *) safeIdentifier:(NSString *)fieldOrTableName;

- (id)connectionSettings;

- (NSString *)selectPart;
- (NSString *)tableAliasConnector;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
