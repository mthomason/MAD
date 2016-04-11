//
//  MTQuerySelectItemsForGroup.m
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuerySelectItemsForGroup.h"
#import <MADFoundation/MADDataColumn.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import "MTDatabaseDataBinding.h"

@interface MTQuerySelectItemsForGroup ()

    @property (nonatomic, copy) NSString *tableName;
    @property (nonatomic, weak) NSArray *sortDescriptors;
    @property (nonatomic, weak) NSArray *columnKeys;
    @property (nonatomic, weak) NSArray *whereClause;

@end

@implementation MTQuerySelectItemsForGroup

- (instancetype)initWithTableName:(NSString *)tableName sortDescriptors:(NSArray *)sortDescriptors
                       columnKeys:(NSArray *)columnKeys whereClause:(NSArray *)whereClause {
    if (self = [super init]) {
        _tableName = tableName.copy;
        _sortDescriptors = sortDescriptors;
        _columnKeys = columnKeys;
        _whereClause = whereClause;
    }
    return self;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSString * __weak tableName = object[@(MTQuerySelectTableName)];
        _tableName = tableName.copy;
        
        NSArray * __weak sd = object[@(MTQuerySelectSortDescriptors)];
        NSArray *sortDescriptors = [[NSArray alloc] initWithArray:sd copyItems:YES];
        self.sortDescriptors = sortDescriptors;
        
        NSArray * __weak fieldKeys = object[@(MTQuerySelectFieldKeys)];
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithArray:fieldKeys copyItems:YES];
        [columnKeys addObject:MADIdentifierROWID];
        self.columnKeys = columnKeys;
        
        NSArray * __weak wc = object[@(MTQuerySelectPredicates)];
        NSArray *whereClause = [[NSArray alloc] initWithArray:wc copyItems:YES];
        [self setWhereClause:whereClause];
        
        NSDictionary * __weak cols = object[@(MTQuerySelectFieldDescriptors)];
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithDictionary:cols copyItems:YES];
        MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
        rowid.columnType = MTDataTypeInteger;
        columns[MADIdentifierROWID] = rowid;
        self.columns = columns;
  
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {

    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT "];
    NSUInteger columnCounter = 0;
    
    for (NSString *key in [self columnKeys]) {
        
        if (columnCounter != 0) {
            [sql appendString:@", "];
        }
        [sql appendFormat:@"\"%@\"", key];
        columnCounter++;
    }
    [sql appendFormat:@" FROM %@", self.tableName];
    
    NSString * __weak whereClauseWithParameters = [self whereClauseWithParameters:self.whereClause];
    [sql appendString:whereClauseWithParameters];
    
    NSString * __weak orderByClauseWithSortDescriptors = [self orderByClauseWithSortDescriptors:self.sortDescriptors];
    [sql appendString:orderByClauseWithSortDescriptors];

    return sql;
}

@end
