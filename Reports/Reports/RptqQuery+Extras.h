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
#import "MTProtocolCompare.h"

@class RptqDocument, MTDatabase;

@interface RptqQuery (Extras) <MTProtocolCompare>

- (RptqDocumentSection *)documentSectionForRow:(NSInteger)row;
- (RptqQueryGroup *)firstQueryGroup;
- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
- (NSArray *)sortedQueryGroups;
- (void)deleteQueryGroupAtIndex:(NSInteger)index;
- (NSUInteger)numberOfTables;
- (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)mainDatabase;

@end

#endif
