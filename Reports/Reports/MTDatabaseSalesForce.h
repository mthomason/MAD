//
//  MNSDatabaseSalesForce.h
//  Reports
//
//  Created by Michael Thomason on 11/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseSalesForce_h
#define Reports_MTDatabaseSalesForce_h

#import "MTDatabase.h"
#import "Constants.h"
#import "SFRestAPI.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument+Extras.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import "SFOAuthCoordinator.h"

#import "MTAlertView.h"

@class SFOAuthCoordinatorDelegate;
@class SFRestDelegate;

@interface MTDatabaseSalesForce : MTDatabase
    <SFOAuthCoordinatorDelegate, SFRestDelegate>

- (NSString *)getSqlForQuery:(RptqQuery *)query;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;
- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)cacheReportQueryForDocument:(RptqDocument *)document
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

- (NSString *)identifier;

- (id)connectionSettings;

@end

#endif
