//
//  MTDatabaseCache.m
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseCache.h"
#import "MADDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"
#import <Foundation/NSString.h>

@implementation MTDatabaseCache

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {
    
    id result = nil;
    
    switch (connection.databaseType) {
        case MADDatabaseCategorySqlite3:
            result = [[MTDatabaseSqlite3 alloc] init];
            break;
            
        default:
            break;
    }
    
    [result setDatabaseConnection:connection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return result;
}

- (BOOL)tableExist:(NSString *)tablename {
    return NO;
}

- (void *)databaseHandle {
    return nil;
}

- (void)beginBulkInsert {}
- (void)endBulkInsert {}

- (NSString *)newNativeTypeForDataType:(MADDataType)dataType {
    return nil;
}

@end
