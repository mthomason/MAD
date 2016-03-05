//
//  MTQueryCacheDropTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheDropTable.h"
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"

@interface MTQueryCacheDropTable ()

@property (nonatomic, strong) MTDatabaseConnection *connection;
@property (nonatomic, strong) NSString *tableName;

//- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQueryCacheDropTable

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        NSNumber *keyConnection = @(MTQueryCacheDropTableConnection);
        NSNumber *keyTableName = @(MTQueryCacheDropTableTableName);
        
        NSString *tableName = object[keyTableName];
        [self setTableName:tableName];
        
        MTDatabaseConnection *connection = object[keyConnection];
        [self setConnection:connection];
        
        MTDatabase *db = [MTDatabase databaseFactory:connection];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * _Nullable *)error {
    return [NSString stringWithFormat:@"DROP TABLE IF EXISTS main.%@", [self tableName]];
}

- (BOOL)returnsResults {
    return NO;
}

@end
