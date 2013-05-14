//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable.h"
#import "RptqDocument+ActiveDocument.h"
#import "RptqDocument+Extras.h"

@interface RptqQueryTable (Extras) <MTProtocolCompare>

+ (RptqQueryTable *)createNewQueryTableForTable:(RptqDatabaseSchemaTable *)databaseSchemaTable;
+ (NSUInteger)countOfTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)queryTablesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (id)getQueryTableForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
