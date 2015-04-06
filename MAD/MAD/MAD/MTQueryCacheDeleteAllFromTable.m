//
//  MTQueryCacheDeleteAllFromTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheDeleteAllFromTable.h"
#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

@interface MTQueryCacheDeleteAllFromTable ()

@property (nonatomic, strong) MTDatabaseConnection *connection;
@property (nonatomic, strong) NSString *tableName;

@end

@implementation MTQueryCacheDeleteAllFromTable

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheDeleteAllFromTableConnection = @(MTQueryCacheDeleteAllFromTableConnection);
        NSNumber *keyMTQueryCacheDeleteAllFromTableTableName = @(MTQueryCacheDeleteAllFromTableTableName);
        
        NSString *tableName = object[keyMTQueryCacheDeleteAllFromTableTableName];
        [self setTableName:tableName];
        
        MTDatabaseConnection *connection = object[keyMTQueryCacheDeleteAllFromTableConnection];
        [self setConnection:connection];
        
        MTDatabase *db = [MTDatabase databaseFactory:connection];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
}

- (BOOL)returnsResults {
    return NO;
}

@end
