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
#import <MADDataStructures/MTProtocolCompare.h>
#import <MADDataStructures/MTProtocolLog.h>

@class MTDatabaseTable;

@interface RptqDatabaseSchemaTable (Extras) <MTProtocolCompare, MTProtocolLog>

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                               label:(NSString *)label
                                                         labelPlural:(NSString *)labelPlural
                                                                name:(NSString *)name
                                                        andQueryable:(BOOL)queryable;

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                            andTable:(MTDatabaseTable *)table;

+ (RptqDatabaseSchemaTable *)databaseSchemaTableForDatabase:(RptqDatabase *)database andTableName:(NSString *)name;

@end

#endif
