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

@class RptqDocument;
@class MTDatabase;
@class RptqDocumentSection;
@class RptqDatabaseSchemaTable;

@interface RptqQuery (Extras)

    - (RptqQueryGroup *)firstQueryGroup;
    - (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
    - (NSArray *)sortedQueryGroups;
    - (NSUInteger)numberOfTables;
    - (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)database;
    - (NSUInteger)sectionCount;

@end

#endif
