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

@property (nonatomic, copy) NSString *tableName;

@end

@implementation MTQueryCacheDropTable

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        
        NSString *tableName = [[NSString alloc] initWithString: object];
        [self setTableName:tableName];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSString *tablename = self.tableName;
    NSString * __autoreleasing Sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS main.%@", tablename];
    return Sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
