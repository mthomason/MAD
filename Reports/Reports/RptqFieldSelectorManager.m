//
//  RptqDatabaseSchemaFieldSelectorManager.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqFieldSelectorManager.h"
#import "UIViewTableSectionHeaderDatabaseTable.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

@implementation RptqDatabaseSchemaFieldSelectorManager

- (instancetype)initWithTable:(RptqQueryTable *)sectionTable {
	self = [super init];
	if (self) {

        NSMutableArray *rh = [[NSMutableArray alloc] init];
		[self setRowHeights: rh];
        
        [self setTable: sectionTable];

        NSSet *fieldsSet = [[self table] hasQueryFields];
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fieldsArray = [fieldsSet sortedArrayUsingDescriptors:@[namesAccending]];

        NSArray *sectionFields = [[NSArray alloc] initWithArray: fieldsArray];
        [self setFields: sectionFields];
	}
	return self;
}


- (NSUInteger)countOfRowHeights {
	return [_rowHeights count];
}

- (id)objectInRowHeightsAtIndex:(NSUInteger)idx {
	return _rowHeights[idx];
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
	_rowHeights[idx] = anObject;
}

- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray {
	[_rowHeights replaceObjectsAtIndexes:indexes withObjects:rowHeightArray];
}

@end
