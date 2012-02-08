//
//  RptqFieldSelectorManager.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIViewSectionHeaderTable;
@class RptqTable;


@interface RptqFieldSelectorManager : NSObject 

@property (assign) BOOL open;
@property (retain) RptqTable *table;
@property (retain) NSArray *fields;
@property (retain) UIViewSectionHeaderTable* headerView;

@property (nonatomic, retain) NSMutableArray *rowHeights;

- (id)initWithTable:(RptqTable *)sectionTable;

- (NSUInteger)countOfRowHeights;
- (id)objectInRowHeightsAtIndex:(NSUInteger)idx;
- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx;
- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject;
- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes;
- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray;

@end
