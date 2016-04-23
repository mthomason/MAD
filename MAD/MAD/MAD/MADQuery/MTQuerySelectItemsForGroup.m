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
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MTQuerySelectTableName];
        NSString *tableName = object[keyTableName];
        self.tableName = tableName;
        
        NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MTQuerySelectSortDescriptors];
        NSArray *sortDescriptors = object[keySortDescriptors];
        self.sortDescriptors = sortDescriptors;
        
        NSNumber *keyFieldKeys = [[NSNumber alloc] initWithShort: MTQuerySelectFieldKeys];
        NSArray *columnKeys = object[keyFieldKeys];
        
        NSMutableArray *mutableColumnKeys = [[NSMutableArray alloc] initWithArray: columnKeys];
        [mutableColumnKeys addObject:MADIdentifierROWID];
        self.columnKeys = mutableColumnKeys;
        
        NSNumber *keyPredicates = [[NSNumber alloc] initWithShort: MTQuerySelectPredicates];
        NSArray *whereClause = object[keyPredicates];
        self.whereClause = whereClause;
        
        NSNumber *keyFieldDescriptors = [[NSNumber alloc] initWithShort: MTQuerySelectFieldDescriptors];
        NSDictionary *columns = object[keyFieldDescriptors];
        NSMutableDictionary *mutableColumns = [NSMutableDictionary dictionaryWithDictionary:columns];
        
        MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
        rowid.type = MTDataTypeInteger;
        mutableColumns[MADIdentifierROWID] = rowid;
        self.columns = mutableColumns;
  
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {

    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT "];
    NSUInteger columnCounter = 0;
    
    NSArray *columnKeys = self.columnKeys;
    for (NSString *key in columnKeys) {
        
        if (columnCounter != 0) {
            [sql appendString:@", "];
        }
        [sql appendFormat:@"\"%@\"", key];
        columnCounter++;
    }
    [sql appendFormat:@" FROM %@", self.tableName];
    [sql appendString:[self whereClauseWithParameters:self.whereClause]];
    [sql appendString:[self orderByClauseWithSortDescriptors:self.sortDescriptors]];

    return sql;
}

@end
