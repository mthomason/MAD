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

    @property (nonatomic, strong) NSString *tableName;
    @property (nonatomic, strong) NSString *columnName;
    @property (nonatomic, strong) NSArray *sortDescriptors;
    @property (nonatomic, strong) NSArray *columnKeys;
    @property (nonatomic, strong) NSArray *whereClause;

@end

@implementation MTQuerySelectItemsForGroup

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSString *tableName = [NSString stringWithString:object[@(MTQuerySelectTableName)]];
        [self setTableName:tableName];
        
        NSArray *sortDescriptors = [NSArray arrayWithArray:object[@(MTQuerySelectSortDescriptors)]];
        [self setSortDescriptors:sortDescriptors];
        
        NSMutableArray *columnKeys = [NSMutableArray arrayWithArray:object[@(MTQuerySelectFieldKeys)]];
        [columnKeys addObject:MADIdentifierROWID];
        [self setColumnKeys:columnKeys];
        
        NSArray *whereClause = [NSArray arrayWithArray:object[@(MTQuerySelectPredicates)]];
        [self setWhereClause:whereClause];
        
        NSMutableDictionary *columns = [NSMutableDictionary dictionaryWithDictionary:object[@(MTQuerySelectFieldDescriptors)]];
        MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
        [rowid setColumnType:@(MTDataTypeInteger)];
        columns[MADIdentifierROWID] = rowid;
        [self setColumns:columns];
  
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
    [sql appendFormat:@" FROM %@", [self tableName]];
    [sql appendString:[self whereClauseWithParameters:[self whereClause]]];
    [sql appendString:[self orderByClauseWithSortDescriptors:[self sortDescriptors]]];

    return sql;
}

@end
