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
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

@interface RptqDatabaseSchemaFieldSelectorManager ()

    - (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation RptqDatabaseSchemaFieldSelectorManager

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initWithTable:(RptqQueryTable *)sectionTable {
	self = [super init];
	if (self) {

        NSMutableArray *rh = [[NSMutableArray alloc] init];
		self.rowHeights = rh;
        self.table = sectionTable;

        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name"
                                                                       ascending:YES];
        NSArray *sortDescriptors = @[namesAccending];
        NSArray *fieldsArray = [self.table.hasQueryFields sortedArrayUsingDescriptors:sortDescriptors];
        NSArray *sectionFields = [[NSArray alloc] initWithArray: fieldsArray];
        self.fields = sectionFields;
	}
	return self;
}


- (NSUInteger)countOfRowHeights {
	return [self.rowHeights count];
}

- (id)objectInRowHeightsAtIndex:(NSUInteger)idx {
	return self.rowHeights[idx];
}

- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx {
	[self.rowHeights insertObject:anObject atIndex:idx];
}

- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes {
	[self.rowHeights insertObjects:rowHeightArray atIndexes:indexes];
}

- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx {
	[self.rowHeights removeObjectAtIndex:idx];
}

- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes {
	[self.rowHeights removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject {
	self.rowHeights[idx] = anObject;
}

- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray {
	[self.rowHeights replaceObjectsAtIndexes:indexes withObjects:rowHeightArray];
}

@end
