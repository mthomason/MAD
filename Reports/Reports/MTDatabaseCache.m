//
//  MTDatabaseCache.m
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseCache.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"

@implementation MTDatabaseCache

+ (id)databaseFactory:(MTDatabaseConnection *)connection {
    
    NSString *identifier = [connection databaseTypeIdentifier];
    
    id result = nil;
    if ([[MTDatabaseSqlite3 identifier] isEqualToString:identifier]) {
        
        result = [[MTDatabaseSqlite3 alloc] init];
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

- (NSString *)nativeTypeForDataType:(MTDataType)dataType {
    return nil;
}

@end
