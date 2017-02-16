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

#import <Foundation/NSSortDescriptor.h>

#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

static NSString * const MADKeyDBSchemaFieldName = @"databaseSchemaField.name";

@interface RptqDatabaseSchemaFieldSelectorManager ()

    - (instancetype)init NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, readwrite, strong) NSMutableArray *rowHeights;

@end

@implementation RptqDatabaseSchemaFieldSelectorManager

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (instancetype)initWithTable:(RptqQueryTable *)sectionTable {
	if (self = [super init]) {

        NSMutableArray *rh = [[NSMutableArray alloc] init];
		self.rowHeights = rh;
        self.table = sectionTable;

        NSSortDescriptor *namesAccending;
        namesAccending = [[NSSortDescriptor alloc] initWithKey: MADKeyDBSchemaFieldName
                                                     ascending: YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: namesAccending, nil];
        NSArray *fieldsArray = [self.table.hasQueryFields sortedArrayUsingDescriptors:sortDescriptors];
        NSArray *sectionFields = [[NSArray alloc] initWithArray: fieldsArray];
        self.fields = sectionFields;
	}
	return self;
}


- (NSUInteger)countOfRowHeights {
	return (self.rowHeights).count;
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
