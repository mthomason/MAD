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
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@class MTDatabaseTable;

@interface RptqDatabaseSchemaTable (Extras) <MTProtocolCompare, MTProtocolLog>

+ (instancetype)databaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                            label:(NSString *)label
                                                      labelPlural:(NSString *)labelPlural
                                                             name:(NSString *)name
                                                     andQueryable:(BOOL)queryable;

+ (instancetype)databaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                         andTable:(MTDatabaseTable *)table;

+ (instancetype)databaseSchemaTableForDatabase:(RptqDatabase *)database
                                  andTableName:(NSString *)name;

@end

#endif
