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
#import <Foundation/NSString.h>

@implementation MTDatabaseCache

+ (instancetype)newDatabaseWithConnection:(MTDatabaseConnection *)connection NS_RETURNS_RETAINED {
    
    NSString *identifier = [connection databaseTypeIdentifier];
    
    id result = nil;
    if ([MADIdentifierDatabaseSqlite3 isEqualToString:identifier]) {
        
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

- (NSString *)newNativeTypeForDataType:(MTDataType)dataType {
    return nil;
}

@end
