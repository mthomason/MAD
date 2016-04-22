//
//  MTQueryCacheCreateIndex.m
//  MAD
//
//  Created by Michael Thomason on 5/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheIndexCreate.h"
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"
#import <MADFoundation/MADDataColumn.h>

@interface MTQueryCacheIndexCreate ()

@property (nonatomic, strong) NSString *indexName;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryCacheIndexCreate

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheIndexDrop expects NSDictionary.");
        
        NSNumber *keyIndexName = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateIndexName];
        
        NSString *indexName = object[keyIndexName];
        self.indexName = indexName;

        NSNumber *keyTableName = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateTableName];
        NSString *tableName = object[keyTableName];
        self.tableName = tableName;
        
        NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateSortDescriptors];
        NSArray *sortDescriptors = object[keySortDescriptors];
        self.sortDescriptors = sortDescriptors;
        
        NSNumber *keyColumns = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateColumns];
        NSDictionary *columns = object[keyColumns];
        self.columns = columns;
        
        self.queryObject = object;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {

    NSMutableString *sql = [[NSMutableString alloc] init];

    if (self.sortDescriptors.count > 0) {
        NSString *queryCreateIndexFirstPart = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS main.%@ ON %@ ", [self indexName], [self tableName]];
        
        [sql appendString: queryCreateIndexFirstPart];
        if ([[self sortDescriptors] count] > 0) {
            [sql appendString:@" ("];
            NSUInteger sortCounter = 0;
            for (NSSortDescriptor *sortDescriptor in self.sortDescriptors) {

                if (sortCounter != 0) [sql appendString:@", "];
                MADDataColumn *column = self.columns[sortDescriptor.key];
                NSAssert(column != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
                NSString *sortDirection = [MTDatabaseSqlite3 sortDescForColumnType: column.nativeType
                                                                         ascending: sortDescriptor.ascending];
                [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDirection];
                sortCounter++;
            }
            [sql appendString:@" )"];
        }
    }
    
    return sql;
}

- (BOOL)returnsResults { return NO; }

@end
