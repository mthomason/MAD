//
//  RptqDatabaseSchemaFieldSelectorManager.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqFieldSelectorManager.h"
#import "UIViewTableSectionHeaderDatabaseTable.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

@implementation RptqDatabaseSchemaFieldSelectorManager

- (void)dealloc {
    
    [_table release];
    [_fields release];
    [_headerView release];
    [_rowHeights release];

    [super dealloc];
}

- (id)initWithTable:(RptqQueryTable *)sectionTable {
	self = [super init];
	if (self) {

        NSMutableArray *rh = [[NSMutableArray alloc] init];
		[self setRowHeights: rh];
        [rh release];
        
        [self setTable: sectionTable];

        NSSet *fieldsSet = [[self table] hasQueryFields];
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fieldsArray = [fieldsSet sortedArrayUsingDescriptors:@[namesAccending]];

        NSArray *sectionFields = [[NSArray alloc] initWithArray: fieldsArray];
        [self setFields: sectionFields];
        [sectionFields release];
        [namesAccending release];
	}
	return self;
}


- (NSUInteger)countOfRowHeights {
	return [_rowHeights count];
}

- (id)objectInRowHeightsAtIndex:(NSUInteger)idx {
	return [_rowHeights objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx {
	[_rowHeights insertObject:anObject atIndex:idx];
}

- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes {
	[_rowHeights insertObjects:rowHeightArray atIndexes:indexes];
}

- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx {
	[_rowHeights removeObjectAtIndex:idx];
}

- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes {
	[_rowHeights removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject {
	[_rowHeights replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray {
	[_rowHeights replaceObjectsAtIndexes:indexes withObjects:rowHeightArray];
}

@end
