//
//  MTDataTableVirtual.m
//  MAD
//
//  Created by Michael Thomason on 4/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTableVirtual.h"
#import "MTDataColumn.h"

@interface MTDataTableVirtual ()

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong, readwrite) NSMutableArray *sortIndex;     // A sorted array of dictionaries

@end

@implementation MTDataTableVirtual

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForRowIds:(NSIndexSet *)rowids {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    
    NSString *key = [MTDataTableVirtual keySortIndex];
    [encoder encodeObject: _sortIndex forKey: key];
    
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if(self) {
        
        NSString *key = [MTDataTableVirtual keySortIndex];
        NSMutableArray *sortIndex = [decoder decodeObjectForKey:key];
        [self setSortIndex:sortIndex];
        
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        
        [self initalize];
        
    }
    return self;
}

- (void)initalize {
    NSMutableArray *sortIndex = [[NSMutableArray alloc] init];
    [self setSortIndex:sortIndex];
}

- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    self = [super initWithNumberOfColumns:numberOfColumns];
    if (self) {
        
        NSMutableArray *sortIndex = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        [self setSortIndex:sortIndex];
        
    }
    return self;
}

- (void)loadWithPlist:(id)plist {
    [super loadWithPlist:plist];
    
    NSString *keySortIndex = [MTDataTableVirtual keySortIndex];
    NSArray *sortIndexArray = [plist objectForKey:keySortIndex];
    NSMutableArray *sortIndex = [[NSMutableArray alloc] initWithArray:sortIndexArray];
    [self setSortIndex:sortIndex];
}

- (id)initWithId:(NSUInteger)objectId {
    self = [super initWithId:objectId];
    if (self) {

        [self initalize];

    }
    return self;
}

- (id)plist {
    NSDictionary *superPlist = [super plist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    NSString *keySortIndex = [MTDataTableVirtual keySortIndex];
    plist[keySortIndex] = [self sortIndex];
    return plist;
}

- (void)addColumn:(MTDataColumn *)column {
    NSString *identifier = [[NSString alloc] initWithString:[column identifier]];
    [[self columnKeys] addObject:identifier];
    [self columns][identifier] = column;
}

- (NSArray *)allObjects {
    return [self sortIndex];
}


- (void)addColumnWithIdentifier:(NSString *)identifier  {
    [self addColumnWithIdentifier:identifier andDefaultValue:[NSNull null]];
}

- (void)addColumnWithIdentifier:(NSString *)identifier andDefaultValue:(id)defaultValue {
    NSUInteger length = [self numberOfRows];
    MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:identifier];
    [dataColumn addRows:length];
    [self addColumn:dataColumn];
}

- (NSUInteger)numberOfRows {
    return [self rowCounter];
}

- (NSUInteger)sortedIndexForIndex:(NSUInteger)index {
    NSUInteger sortedIndex;
    if ([[self sortDescriptors] count] > 0) {
        sortedIndex = [[self sortIndex] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj objectForKey:@"~rowid~"] integerValue] == index) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
    } else {
        sortedIndex = index;
    }
    return sortedIndex;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [self objectAtRow:idx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len {
    return [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSEnumerator *)objectEnumerator {
    return [[self sortIndex] objectEnumerator];
}

- (NSEnumerator *)columnsEnumerator {
    return [[self columns] objectEnumerator];
}

- (id)objectAtRow:(NSInteger)row {
    return [self sortIndex][row];
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    NSString *fieldKey = [[self columnKeys] objectAtIndex:column];
    MTDataColumn *dataInColumn = [[self columns] objectForKey:fieldKey];
    NSUInteger sortedIndex = [self sortedIndexForIndex:row];
    id objectForField = [dataInColumn objectAtIndex:sortedIndex];
    return objectForField;
}

- (id)objectAtIndex:(NSInteger)index {
    NSUInteger sortedIndex = [self sortedIndexForIndex:index];
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:[[self columnKeys] count]];
    for (NSString *fieldKey in [self columnKeys]) {
        NSArray *dataInColumn = [[self columns] objectForKey:fieldKey];
        id objectForField = [dataInColumn objectAtIndex:sortedIndex];
        [data setObject:objectForField forKey:fieldKey];
    }
    return data;
}

- (void)addRow:(NSArray *)row {
    NSUInteger index = 0;
    NSUInteger numberOfColumns = [self numberOfColumns];
    NSMutableDictionary *indexedRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
    NSUInteger numberOfRows = [self rowCounter];
    NSNumber *ogRowIndex = @(numberOfRows);
    for (id object in row) {
        NSString *key = [self columnKeys][index];
        MTDataColumn *column = [self columns][key];
        [column addObject:object];
        [indexedRow setObject:object forKey:key];
        [indexedRow setObject:ogRowIndex forKey:@"~rowid~"];
        index++;
    }
    [[self sortIndex] addObject:indexedRow];
    numberOfRows++;
    [self setRowCounter:numberOfRows];
}

- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {
    for (id key in [self columnKeys]) {
        MTDataColumn *column = [[self columns] objectForKey:key];
        id obj = [row objectForKey:key];
        if (obj == nil) obj = @"";
        [column addObject:obj];
    }
    [[self sortIndex] addObject:row];
    NSUInteger numberOfRows = [self rowCounter] + 1;
    [self setRowCounter:numberOfRows];
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {
    [[self sortIndex] sortUsingDescriptors:sortDescriptors];
    [[self sortDescriptors] removeAllObjects];
    [[self sortDescriptors] addObjectsFromArray:sortDescriptors];
}

- (NSUInteger)count {
    return [self numberOfRows];
}

- (NSUInteger)numberOfColumns {
    return [[self columnKeys] count];
}

+ (NSString *)keySortIndex {
    SEL selSortIndex = @selector(sortIndex);
    return NSStringFromSelector(selSortIndex);
}

- (NSArray *)objectAtRow:(NSInteger)row limit:(NSUInteger)limit {
    NSRange range = NSMakeRange(row, limit);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    return [[self sortIndex] objectsAtIndexes:indexSet];
}

- (void)removeAllObjects {
    for (MTDataColumn *column in [[self columns] objectEnumerator]) {
        [column removeAllObjects];
    }
    [[self columns] removeAllObjects];
    [[self columnKeys] removeAllObjects];
    [[self sortIndex] removeAllObjects];
    [[self sortDescriptors] removeAllObjects];
    [self setRowCounter:0];
}

- (void)beginBulkInsert {}
- (void)endBulkInsert {}

@end
