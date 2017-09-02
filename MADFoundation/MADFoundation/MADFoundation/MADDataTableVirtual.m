//
//  MADDataTableVirtual.m
//  MAD
//
//  Created by Michael Thomason on 4/25/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDataTableVirtual.h"
#import <Foundation/NSStream.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSDictionary.h>
#import <MADFoundation/MADDataColumn.h>

@interface MADDataTableVirtual ()

    @property (nonatomic, strong) NSInputStream *inputStream;
    @property (nonatomic, strong) NSOutputStream *outputStream;

    @property (nonatomic, strong, readwrite) NSMutableArray *sortIndex;     // A sorted array of dictionaries

@end

@implementation MADDataTableVirtual

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)dataForRow:(NSUInteger)cacheId {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableArray *sortIndex = [[NSMutableArray alloc] init];
        self.sortIndex = sortIndex;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        NSString *key = [MADDataTableVirtual keySortIndex];
        NSMutableArray *sortIndex = [decoder decodeObjectForKey:key];
        self.sortIndex = sortIndex;
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId {
    if (self = [super initWithId:objectId]) {
        NSMutableArray *sortIndex = [[NSMutableArray alloc] init];
        self.sortIndex = sortIndex;
    }
    return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    if (self = [super initWithNumberOfColumns:numberOfColumns]) {
        NSMutableArray *sortIndex = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        self.sortIndex = sortIndex;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    NSString *key = [MADDataTableVirtual keySortIndex];
    [encoder encodeObject: _sortIndex forKey: key];
}

- (void)loadWithPlist:(NSDictionary *)plist {
    [super loadWithPlist:plist];
    
    NSString *keySortIndex = [MADDataTableVirtual keySortIndex];
    NSArray *sortIndexArray = plist[keySortIndex];
    
    NSMutableArray *sortIndex = [[NSMutableArray alloc] initWithArray:sortIndexArray];
    self.sortIndex = sortIndex;
}

- (NSDictionary *)copyPlist {
    NSDictionary *superPlist = [super copyPlist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    NSString *keySortIndex = [MADDataTableVirtual keySortIndex];
    plist[keySortIndex] = self.sortIndex;
    return plist;
}

- (void)addColumn:(MADDataColumn *)column {
    NSString *identifier = [[NSString alloc] initWithString:column.identifier];
    [self.columnKeys addObject:identifier];
    self.columns[identifier] = column;
}

- (NSArray *)allObjects {
    return self.sortIndex;
}

- (void)addColumnWithIdentifier:(NSString *)identifier  {
    [self addColumnWithIdentifier:identifier andDefaultValue:[NSNull null]];
}

- (void)addColumnWithIdentifier:(NSString *)identifier andDefaultValue:(id)defaultValue {
    NSUInteger length = [self numberOfRows];
    MADDataColumn *dataColumn = [[MADDataColumn alloc] initWithIdentifier:identifier];
    [dataColumn addRows:length];
    [self addColumn:dataColumn];
}

- (NSUInteger)numberOfRows {
    return self.rowCounter;
}

- (NSUInteger)sortedIndexForIndex:(NSUInteger)index {
    NSUInteger sortedIndex;
    if ((self.sortDescriptors).count > 0) {
        sortedIndex = [self.sortIndex indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj[@"~rowid~"] unsignedIntegerValue] == index) {
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

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    return [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSEnumerator *)objectEnumerator {
    return [self.sortIndex objectEnumerator];
}

- (NSEnumerator *)columnsEnumerator {
    return [self.columns objectEnumerator];
}

- (id)objectAtRow:(NSUInteger)row {
    return self.sortIndex[row];
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    NSString *fieldKey = self.columnKeys[column];
    MADDataColumn *dataInColumn = self.columns[fieldKey];
    NSUInteger sortedIndex = [self sortedIndexForIndex:row];
    id objectForField = [dataInColumn objectAtIndex:sortedIndex];
    return objectForField;
}

// WTF: What is happening here.
- (id)objectAtIndex:(NSUInteger)index {
    NSUInteger sortedIndex = [self sortedIndexForIndex:index];
    
    NSMutableDictionary *data;
    data = [[NSMutableDictionary alloc] initWithCapacity:(self.columnKeys).count];
    NSArray *dataInColumn;
    NSString *fieldKey, *key;
    for (fieldKey in self.columnKeys) {
        key = fieldKey;
        if (key.length > 0) {
            dataInColumn = self.columns[key];
            // FIXME: what is this?
            NSAssert(NO, @"Remove after testing this warning.");
            id objectForField = dataInColumn[sortedIndex];
            data[key] = objectForField;
        }
    }
    return data;
}

- (void)addRow:(NSArray *)row error:(NSError * __autoreleasing *)error {
    NSUInteger index = 0;
    NSUInteger numberOfColumns = [self numberOfColumns];
    NSMutableDictionary *indexedRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
    NSUInteger numberOfRows = self.rowCounter;
    NSNumber *ogRowIndex = @(numberOfRows);
    for (id object in row) {
        NSString *key = self.columnKeys[index];
        MADDataColumn *column = self.columns[key];
        [column addObject:object];
        indexedRow[key] = object;
        indexedRow[@"~rowid~"] = ogRowIndex;
        index++;
    }
    [self.sortIndex addObject:indexedRow];
    numberOfRows++;
    self.rowCounter = numberOfRows;
}

- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {
    for (id key in self.columnKeys) {
        MADDataColumn *column = self.columns[key];
        id obj = row[key];
        if (obj == nil) obj = @"";
        [column addObject:obj];
    }
    [self.sortIndex addObject:row];
    NSUInteger numberOfRows = self.rowCounter + 1;
    self.rowCounter = numberOfRows;
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {
    [self.sortIndex sortUsingDescriptors:sortDescriptors];
    [self.sortDescriptors removeAllObjects];
    [self.sortDescriptors addObjectsFromArray:sortDescriptors];
}

- (NSUInteger)count {
    return [self numberOfRows];
}

- (NSUInteger)numberOfColumns {
    return (self.columnKeys).count;
}

+ (NSString *)keySortIndex {
    SEL selSortIndex = @selector(sortIndex);
    return NSStringFromSelector(selSortIndex);
}

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
    NSRange range = NSMakeRange(row, limit);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    return [self.sortIndex objectsAtIndexes:indexSet];
}

- (void)removeAllObjects {
    for (MADDataColumn *column in [self.columns objectEnumerator]) {
        [column removeAllObjects];
    }
    [self.columns removeAllObjects];
    [self.columnKeys removeAllObjects];
    [self.sortIndex removeAllObjects];
    [self.sortDescriptors removeAllObjects];
    self.rowCounter = 0;
}

- (void)beginBulkInsert {}
- (void)endBulkInsert {}

@end
