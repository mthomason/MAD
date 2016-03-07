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
#import <MADDataStructures/MTProtocolCompare.h>

@class RptqDocument, MTDatabase, RptqDocumentSection, RptqDatabaseSchemaTable;

@interface RptqQuery (Extras) <MTProtocolCompare>

- (RptqDocumentSection *)documentSectionForRow:(NSUInteger)row;
- (RptqQueryGroup *)firstQueryGroup;
- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
- (NSArray *)sortedQueryGroups;
- (NSUInteger)numberOfTables;
- (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)mainDatabase;
- (RptqQueryTable *)addQueryTableBasedOnSchemaTable:(RptqDatabaseSchemaTable *)schemaTable;
- (NSUInteger)sectionCount;

@end

#endif
