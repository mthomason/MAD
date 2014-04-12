//
//  MTTable.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTable.h"
#import "MTDataTableLocation.h"
#import "MTDataColumn.h"

@interface MTDataTable ()

@property (nonatomic, strong, readwrite) NSString *name;

@property (nonatomic, strong, readwrite) NSMutableArray *columnKeys;

@property (nonatomic, assign, readwrite) NSUInteger rowCounter;

@property (nonatomic, strong, readwrite) NSArray *sortDescriptors;

@property (nonatomic, strong, readwrite) NSMutableArray *sortIndex;     // A sorted array of dictionaries
                                                                        // @[
                                                                        //      @{ @"column-1" : obj-1-c1,
                                                                        //         @"column-2" : obj-1-c2,
                                                                        //          ...,
                                                                        //         @"column-n" : obj-1-cn },
                                                                        //      @{ @"column-1" : obj-2-c1,
                                                                        //         @"column-2" : obj-2-c2,
                                                                        //          ...,
                                                                        //         @"column-n" : obj-2-cn },
                                                                        //      @{...},
                                                                        //      @{ @"column-1" : obj-3-c1,
                                                                        //         @"column-2" : obj-3-c2,
                                                                        //          ...,
                                                                        //         @"column-n" : obj-3-cn },
                                                                        // ]

@property (nonatomic, strong, readwrite) NSMutableDictionary *columns;  // The data for fast summeraztion.
                                                                        // @{
                                                                        //      @"column-1" = @[obj-1-c1, obj-2-c1, obj-3-c1, ..., obj-num-rows-c1],
                                                                        //      @"column-2" = @[obj-1-c2, obj-2-c2, obj-3-c2, ..., obj-num-rows-c2],
                                                                        //      ...
                                                                        //      @"column-n" = @[obj-1-cn, obj-2-cn, obj-3-cn, ..., obj-num-rows-cn],
                                                                        // }

@end

@implementation MTDataTable

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject: [self name]
                   forKey: [MTDataTable keyName]];
    
    [encoder encodeObject: [self columnKeys]
                   forKey: [MTDataTable keyColumnKeys]];
    
    [encoder encodeObject: [self columns]
                   forKey: [MTDataTable keyColumns]];

    [encoder encodeInteger: [self rowCounter]
                    forKey: [MTDataTable keyRowCounter]];

    
    [encoder encodeObject: [self sortIndex]
                    forKey: [MTDataTable keySortIndex]];

    
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {

        NSString *name = [decoder decodeObjectForKey: [MTDataTable keyName]];
        [self setName: name];
        
        NSMutableArray *columnKeys = [decoder decodeObjectForKey: [MTDataTable keyColumnKeys]];
        [self setColumnKeys: columnKeys];
        
        NSMutableDictionary *columns = [decoder decodeObjectForKey: [MTDataTable keyColumns]];
        [self setColumns: columns];
        
        NSUInteger rowCounter = [decoder decodeIntegerForKey: [MTDataTable keyRowCounter]];
        [self setRowCounter:rowCounter];
        
        NSMutableArray *sortIndex = [decoder decodeObjectForKey:[MTDataTable keySortIndex]];
        [self setSortIndex:sortIndex];
        
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {

        NSString *name = @"";
        [self setName:name];
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
        [self setColumnKeys:columnKeys];
        
        NSMutableArray *sortIndex = [[NSMutableArray alloc] init];
        [self setSortIndex:sortIndex];

        NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
        [self setColumns:columns];

        [self setRowCounter:0];

    }
    return self;
}

- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    self = [super init];
    if (self) {
        
        NSString *name = @"";
        [self setName:name];
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        [self setColumnKeys:columnKeys];
        
        NSArray *sortDescriptors = [NSArray array];
        [self setSortDescriptors:sortDescriptors];
        
        NSMutableArray *sortIndex = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        [self setSortIndex:sortIndex];
        
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
        [self setColumns:columns];
     
        [self setRowCounter:0];

    }
    return self;
}

- (id)initWithPlist:(id)plist {
    self = [super init];
    if (self) {
        
        NSString *name = [plist objectForKey: [MTDataTable keyName]];
        [self setName: name];
        
        NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
        id columnKeysArray = [plist objectForKey: keyColumnKeys];
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithArray:columnKeysArray];
        [self setColumnKeys: columnKeys];
        
        NSArray *sortDescriptors = [plist objectForKey:[MTDataTable keySortDescriptors]];
        [self setSortDescriptors:sortDescriptors];

        NSMutableArray *sortIndex = [[plist objectForKey:[MTDataTable keySortIndex]] mutableCopy];
        [self setSortIndex:sortIndex];

        NSDictionary *columnsPlist = [plist objectForKey: [MTDataTable keyColumns]];

        NSUInteger count = [columnsPlist count];
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:count];
        for (NSString *key in [columnsPlist keyEnumerator]) {
            @autoreleasepool {
                NSDictionary *columnPlist = [[NSDictionary alloc] initWithDictionary:columnsPlist[key]];
                MTDataColumn *column = [[MTDataColumn alloc] initWithPlist: columnPlist];
                columns[key] = column;
            }
        }
        [self setColumns: columns];
        
        NSUInteger rowCounter = [[plist objectForKey: [MTDataTable keyRowCounter]] integerValue];
        [self setRowCounter:rowCounter];
        
//        for (MTDataColumn *column in [[self columns] objectEnumerator]) {
//            for (NSInteger i=0; i<[self rowCounter]; i++) {
//                id obj = [column objectAtIndex:i];
//                NSLog(@"%@", obj);
//            }
//        }
        
    }
    return self;
}

- (void)addColumn:(MTDataColumn *)column {
    
    NSString *identifier = [[NSString alloc] initWithString:[column identifier]];
    [[self columnKeys] addObject:identifier];
    [self columns][identifier] = column;

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

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    NSString *fieldKey = [[self columnKeys] objectAtIndex:column];
//    NSDictionary *objectsForFieldKeys = [self objectAtIndex:row];
    NSArray *dataInColumn = [[self columns] objectForKey:fieldKey];
    NSUInteger sortedIndex = [self sortedIndexForIndex:row];
    id objectForField = [dataInColumn objectAtIndex:sortedIndex];
    return objectForField;
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

- (id)value:(MTDataTableLocation *)location {
    NSString *key =[self columnKeys][[location column]];
    MTDataColumn *column = [self columns][key];
    return [column objectAtIndex:[location row]];
}

- (NSArray *)sortedRepresentationUsingDescriptors:(NSArray *)sortDescriptors {
    NSArray *sortedIndex = [[self sortIndex] sortedArrayUsingDescriptors:sortDescriptors];
    NSMutableArray *index = [[NSMutableArray alloc] initWithArray:sortedIndex];
    [self setSortIndex:index];
    [self setSortDescriptors:sortDescriptors];
    return sortedIndex;
}

- (NSDictionary *)columnsPlist {
    
    NSMutableDictionary *columnsPlist = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfColumns]];
    for (NSString *key in [[self columns] keyEnumerator]) {
        MTDataColumn *dataColumn = [[self columns] objectForKey:key];
        columnsPlist[key] = [dataColumn plist];
    }
    return columnsPlist;
}

- (id)plist {
    
    NSString *keyName = [MTDataTable keyName];
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    NSString *keyColumns = [MTDataTable keyColumns];
    NSString *keyRowCounter = [MTDataTable keyRowCounter];
    NSNumber *rowCounter = @([self rowCounter]);
    NSString *keySortIndex = [MTDataTable keySortIndex];
    
    NSArray *columnKeys = [[NSArray alloc] initWithArray:[self columnKeys]];
    NSDictionary *columnsPlist = [self columnsPlist];
    return @{
             keyName        : [self name],
             keyColumnKeys  : columnKeys,
             keyColumns     : columnsPlist,
             keyRowCounter  : rowCounter,
             keySortIndex   : [self sortIndex]
             };
}

- (NSUInteger)count {
    return [self numberOfRows];
}

- (NSUInteger)numberOfColumns {
    return [[self columnKeys] count];
}

+ (NSString *)keyName {
    SEL selName = @selector(name);
    return NSStringFromSelector(selName);
}

+ (NSString *)keyColumnKeys {
    SEL selColumnKeys = @selector(columnKeys);
    return NSStringFromSelector(selColumnKeys);
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

+ (NSString *)keyRowCounter {
    SEL selRowCounter = @selector(rowCounter);
    return NSStringFromSelector(selRowCounter);
}
+ (NSString *)keySortDescriptors {
    SEL selSortDescriptors = @selector(sortDescriptors);
    return NSStringFromSelector(selSortDescriptors);
}
+ (NSString *)keySortIndex {
    SEL selSortIndex = @selector(sortIndex);
    return NSStringFromSelector(selSortIndex);
}

@end
