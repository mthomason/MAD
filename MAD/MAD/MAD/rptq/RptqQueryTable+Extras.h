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

@class RptqDocument, RptqDatabase, RptqDatabaseSchemaTable, NSManagedObjectID;

@interface RptqQueryTable (Extras) <MTProtocolCompare>

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                       database:(RptqDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED;

    + (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSString *)copyQueryAlias;
    - (NSString *)tableAlias;

@end

#endif
