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
#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "MTDatabaseTable.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"
@interface RptqDatabaseSchemaTable (Extras) <MTProtocolCompare, MTProtocolLog>

+ (RptqDatabaseSchemaTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label
                                         labelPlural:(NSString *)labelPlural
                                                name:(NSString *)name
                                        andQueryable:(BOOL)queryable;

+ (RptqDatabaseSchemaTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andTable:(MTDatabaseTable *)table;

+ (RptqDatabaseSchemaTable *)getTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                      database:(RptqDatabase *)database
                                  andTableName:(NSString *)name;

+ (RptqQueryTable *)addTableToQuery:(RptqDatabaseSchemaTable *)table forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)getTableForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
