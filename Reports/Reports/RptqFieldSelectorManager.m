//
//  RptqDatabaseSchemaFieldSelectorManager.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqFieldSelectorManager.h"

@implementation RptqDatabaseSchemaFieldSelectorManager

@synthesize open, rowHeights, table, fields, headerView;

- (void)dealloc {
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
	return [rowHeights count];
}

- (id)objectInRowHeightsAtIndex:(NSUInteger)idx {
	return [rowHeights objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx {
	[rowHeights insertObject:anObject atIndex:idx];
}

- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes {
	[rowHeights insertObjects:rowHeightArray atIndexes:indexes];
}

- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx {
	[rowHeights removeObjectAtIndex:idx];
}

- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes {
	[rowHeights removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject {
	[rowHeights replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray {
	[rowHeights replaceObjectsAtIndexes:indexes withObjects:rowHeightArray];
}

@end
