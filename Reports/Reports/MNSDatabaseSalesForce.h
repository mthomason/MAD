//
//  MNSDatabaseSalesForce.h
//  Reports
//
//  Created by Michael Thomason on 11/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabase.h"
#import "Constants.h"
#import "SFOAuthCoordinator.h"
#import "SFRestAPI.h"
#import "RptqTable.h"
//#import "RptqField.h"
#import "UIAlertView+Blocks.h"

#import "MNSDatabaseTable.h"
#import "MNSDatabaseField.h"

@interface MNSDatabaseSalesForce : MNSDatabase
    <SFOAuthCoordinatorDelegate, SFRestDelegate>

- (void)getTables: (void (^)(NSArray *tables))completion;
- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion;

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion;

@end