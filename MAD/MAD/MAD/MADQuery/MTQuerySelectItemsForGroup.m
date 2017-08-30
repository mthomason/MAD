//
//  MADQuerySelectItemsForGroup.m
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTQuerySelectItemsForGroup.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>

#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADDatabaseDataBinding.h>

#import "MADQuerySelectParameters.h"
#import "MTQuery+Sqlite3.h"

@interface MADQuerySelectItemsForGroup ()

    @property (nonatomic, strong) NSString *tableName;
    @property (nonatomic, strong) NSString *columnName;
    @property (nonatomic, strong) NSArray *sortDescriptors;
    @property (nonatomic, strong) NSArray *columnKeys;
    @property (nonatomic, strong) NSArray *whereClause;

@end

@implementation MADQuerySelectItemsForGroup

@synthesize binaryBindings = _binaryBindings;
@synthesize columns = _columns;

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
        self.binaryBindings = binaryBindings;
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.",
                 NSStringFromClass([self class]));
        
        NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
        NSString *tableName = object[keyTableName];
        self.tableName = tableName.copy;
        
        NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
        NSArray *sortDescriptors = object[keySortDescriptors];
        self.sortDescriptors = sortDescriptors.copy;
        
        NSNumber *keyFieldKeys = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
        NSArray *columnKeys = object[keyFieldKeys];
        NSMutableArray *mutableColumnKeys = columnKeys.mutableCopy;
        [mutableColumnKeys addObject:MADIdentifierROWID];
        self.columnKeys = mutableColumnKeys;
        
        NSNumber *keyPredicates = [[NSNumber alloc] initWithShort: MADQuerySelectPredicates];
        NSArray *whereClause = object[keyPredicates];
        self.whereClause = whereClause;
        
        NSNumber *keyFieldDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectFieldDescriptors];
        NSDictionary *columns = object[keyFieldDescriptors];
        NSMutableDictionary *mutableColumns = columns.mutableCopy;
        
        MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
        rowid.type = MADDataTypeInteger;
        mutableColumns[MADIdentifierROWID] = rowid;
        self.columns = mutableColumns;
  
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {

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

- (MADQueryType)type {
    return MADQueryTypeCacheSelectItemsForGroupKeys;
}

@end
