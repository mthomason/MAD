//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryTable_Extras_h
#define Reports_RptqQueryTable_Extras_h

#import "RptqQueryTable.h"
#import <MADDataStructures/MTProtocolCompare.h>

@class NSManagedObjectID;
@class RptqDocument;
@class RptqDatabase;
@class RptqDatabaseSchemaTable;

@interface RptqQueryTable (Extras)
    <MTProtocolCompare>

    + (instancetype)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                       database:(RptqDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSString *)queryAlias;
    - (NSString *)tableAlias;

@end

#endif
