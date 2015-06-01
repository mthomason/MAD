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
#import "MTProtocolCompare.h"

@class RptqDocument, RptqDatabase, RptqDatabaseSchemaTable, NSManagedObjectID;

@interface RptqQueryTable (Extras) <MTProtocolCompare>

+ (RptqQueryTable *)queryTableFactoryForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                           database:(RptqDatabase *)database;
+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)queryAlias;
- (NSString *)tableAlias;

@end

#endif
