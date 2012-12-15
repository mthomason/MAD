//
//  RptqTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqTable.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "MNSDatabaseTable.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@interface RptqTable (Extras) <MTProtocolCompare, MTProtocolLog>

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label
                                         labelPlural:(NSString *)labelPlural
                                                name:(NSString *)name
                                        andQueryable:(BOOL)queryable;

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andTable:(MNSDatabaseTable *)table;

+ (RptqTable *)getTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                      database:(RptqDatabase *)database
                                  andTableName:(NSString *)name;
+ (void)addTableToQuery:(RptqTable *)table forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSUInteger)countOfTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)namesForTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end