//
//  RptqDatabaseSchemaTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaTable_Extras_h
#define Reports_RptqDatabaseSchemaTable_Extras_h

#import "RptqDatabaseSchemaTable.h"
#import <MADDataStructures/MTProtocolLog.h>

@class MADDatabaseTable;

@interface RptqDatabaseSchemaTable (Extras) <MTProtocolLog>

    + (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                                    name:(NSString *)name
                                                            andQueryable:(BOOL)queryable;

    + (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                                andTable:(MADDatabaseTable *)table;

    + (RptqDatabaseSchemaTable *)databaseSchemaTableForDatabase:(RptqDatabase *)database andTableName:(NSString *)name;

@end

#endif
