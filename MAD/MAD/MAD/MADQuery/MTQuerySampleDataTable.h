//
//  MTQuerySampleDataTable.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataTable_h
#define Reports_MTQuerySampleDataTable_h

#import "MTQuery.h"

@class MTDatabaseConnection;
@class RptqDatabaseSchemaTable;

@interface MTQuerySampleDataTable : MTQuery


    @property (nonatomic, copy, readonly) MTDatabaseConnection *databaseConnection;
    - (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection
                           databaseSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable;

    - (NSString *)getSqlWithError:(NSError **)error;

@end

#endif
