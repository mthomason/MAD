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
#import "RptqTable.h"
#import "UIAlertView+Blocks.h"

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
- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)runQuery: (NSString *)query forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (NSString *)identifier;

- (id)connectionSettings;

@end

#endif
