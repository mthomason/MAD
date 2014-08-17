//
//  MTQueryCacheSelectRowId.m
//  MAD
//
//  Created by Michael Thomason on 5/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectRowId.h"

@interface MTQueryCacheSelectRowId ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSNumber *rowId;
@property (nonatomic, strong) NSArray *columnKeys;

@end

@implementation MTQueryCacheSelectRowId

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *key = @(MTQuerySelectFieldKeys);
        NSArray *columnsNames = [object objectForKey:key];
        if (columnsNames) {
            self.columnKeys = [NSArray arrayWithArray:columnsNames];
        }
 
        self.rowId = [object objectForKey:@(MTQuerySelectRowId)];
        
        NSString *tableName = [object objectForKey:@(MTQuerySelectTableName)];
        [self setTableName:tableName];
        
        NSMutableDictionary *columns = [NSMutableDictionary dictionaryWithDictionary:[object objectForKey:@(MTQuerySelectFieldDescriptors)]];
        [self setColumns:columns];
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSString *result;
    if ([self.columnKeys count] > 0) {
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
        result = [NSString stringWithString:sql];
    } else {
        result = [NSString stringWithFormat:@"SELECT * FROM %@", self.tableName];
    }
    return [result stringByAppendingFormat:@" WHERE rowid = %ld", (long)self.rowId.integerValue];
}

@end
