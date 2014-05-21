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

@interface MTQueryCacheIndexCreate ()

@property (nonatomic, strong) NSString *indexName;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryCacheIndexCreate

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheIndexDrop expects NSDictionary.");
        
        NSNumber *keyIndexName = @(MTQueryCacheIndexCreateIndexName);
        NSNumber *keyTableName = @(MTQueryCacheIndexCreateTableName);
        NSNumber *keySortDescriptors = @(MTQueryCacheIndexCreateSortDescriptors);
        
        NSString *indexName = object[keyIndexName];
        [self setIndexName:indexName];

        NSString *tableName = object[keyTableName];
        [self setTableName:tableName];
        
        NSArray *sortDescriptors = object[keySortDescriptors];
        [self setSortDescriptors:sortDescriptors];
        
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {

    NSMutableString *sql = [[NSMutableString alloc] init];

    if ([[self sortDescriptors] count] > 0) {
        NSString *queryCreateIndexFirstPart = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS main.%@ ON %@ ", [self indexName], [self tableName]];
        
        [sql appendString: queryCreateIndexFirstPart];
        if ([[self sortDescriptors] count] > 0) {
            [sql appendString:@" ("];
            NSUInteger sortCounter = 0;
            for (NSSortDescriptor *sortDescriptor in [self sortDescriptors]) {
                if (sortCounter != 0) [sql appendString:@", "];
                NSString *sortDirection = [sortDescriptor ascending] ? @"COLLATE LSASC ASC" : @"COLLATE LSDESC";
                [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDirection];
                sortCounter++;
            }
            [sql appendString:@" )"];
        }
    }
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
