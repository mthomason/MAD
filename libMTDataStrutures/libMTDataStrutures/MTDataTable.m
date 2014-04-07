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
@property (nonatomic, strong, readwrite) NSMutableDictionary *columns;

@end

@implementation MTDataTable

- (id)init {
    self = [super init];
    if (self) {

        NSString *name = @"";
        [self setName:name];
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
        [self setColumnKeys:columnKeys];

        NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
        [self setColumns:columns];

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
        
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
        [self setColumns:columns];
        
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
    [self columns][identifier] = dataColumn;
    
}

- (NSUInteger)numberOfRows {
    NSString *firstKey = [[self columnKeys] firstObject];
    return [[self columns][firstKey] length];
}

- (id)objectAtIndex:(NSInteger)index {
    return [[self table] objectAtIndex:index];
}

- (void)addRow:(NSArray *)row {
    NSUInteger index = 0;
    for (id object in row) {
        NSString *key = [self columnKeys][index];
        MTDataColumn *column = [self columns][key];
        [column addObject:object];
        index++;
    }
}

- (id)value:(MTDataTableLocation *)location {
    NSString *key =[self columnKeys][[location column]];
    MTDataColumn *column = [self columns][key];
    return [column objectAtIndex:[location row]];
}

@end
