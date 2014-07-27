//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable.h"
#import "MTProtocolCompare.h"

@class RptqDocument, RptqDatabaseSchemaTable, NSManagedObjectID;

@interface RptqQueryTable (Extras) <MTProtocolCompare>

+ (instancetype)queryTableWithSchemaTable:(RptqDatabaseSchemaTable *)table;
+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)queryAlias;
- (NSString *)tableAlias;

@end
