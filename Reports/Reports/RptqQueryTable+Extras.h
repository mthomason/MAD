//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable.h"
#import "RptqDocument+ActiveDocument.h"
#import "RptqDocument+Extras.h"

@interface RptqQueryTable (Extras) <MTProtocolCompare>

+ (RptqQueryTable *)createNewQueryTableForTable:(RptqDatabaseSchemaTable *)databaseSchemaTable inDocument:(RptqDocument *)document;
+ (NSUInteger)countOfTablesInQueryForDocument:(RptqDocument *)document;
+ (id)getQueryTableForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)queryAlias;
- (NSString *)tableAlias;

@end
