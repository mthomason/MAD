//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQuery_Extras_h
#define Reports_RptqQuery_Extras_h

#import "RptqQuery.h"

@class RptqDocument, MTDatabase, RptqDocumentSection, RptqDatabaseSchemaTable;

@interface RptqQuery (Extras)

    - (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
    - (NSArray <RptqQueryGroup *> *)sortedQueryGroups;
    - (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)database;
    - (NSUInteger)sectionCount;
    + (NSUInteger)sectionCountFectch:(NSManagedObjectID *)queryObjectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
