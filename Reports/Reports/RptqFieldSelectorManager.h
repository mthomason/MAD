//
//  RptqDatabaseSchemaFieldSelectorManager.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaFieldSelectorManager_h
#define Reports_RptqDatabaseSchemaFieldSelectorManager_h

#import <Foundation/Foundation.h>
#import "UIViewTableSectionHeaderDatabaseTable.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

@interface RptqDatabaseSchemaFieldSelectorManager : NSObject 

@property (assign) BOOL open;
@property (retain) RptqQueryTable *table;
@property (retain) NSArray *fields;
@property (retain) UIViewTableSectionHeaderDatabaseTable *headerView;
@property (nonatomic, retain) NSMutableArray *rowHeights;

- (id)initWithTable:(RptqQueryTable *)sectionTable;

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
