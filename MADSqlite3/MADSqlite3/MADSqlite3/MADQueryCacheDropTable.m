//
//  MADQueryCacheDropTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheDropTable.h"
#import <Foundation/NSString.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheDropTable ()
    @property (nonatomic, copy) NSString *tableName;
@end

@implementation MADQueryCacheDropTable

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        
        NSString *tableName = [[NSString alloc] initWithString: object];
        self.tableName = tableName;
        
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    NSString *tablename = self.tableName;
    NSString * __autoreleasing Sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS main.%@", tablename];
    return Sql;
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCacheDropTable;
}

@end
