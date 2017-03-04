//
//  RptqDatabaseSchemaFieldSelectorManager.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaFieldSelectorManager_h
#define Reports_RptqDatabaseSchemaFieldSelectorManager_h

#import <Foundation/NSObject.h>

@class RptqQueryTable, NSMutableArray, NSIndexSet, MADDatabaseTableSectionHeaderView;

@interface RptqDatabaseSchemaFieldSelectorManager : NSObject 

    @property (nonatomic, assign) BOOL open;
    @property (nonatomic, strong) RptqQueryTable *table;
    @property (nonatomic, strong) NSArray *fields;
    @property (nonatomic, strong) MADDatabaseTableSectionHeaderView *headerView;

    - (instancetype)initWithTable:(RptqQueryTable *)sectionTable NS_DESIGNATED_INITIALIZER;

    - (NSUInteger)countOfRowHeights;
    - (id)objectInRowHeightsAtIndex:(NSUInteger)idx;
    - (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx;
    - (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx;
    - (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject;
    - (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes;
    - (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes;
    - (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray;

@end

#endif
