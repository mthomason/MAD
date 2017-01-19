//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//
/*
#import "MTDatabaseSqlite3.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import "MADDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"

@implementation MTDatabaseSqlite3

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {
    
    id result = nil;
    
    switch (connection.databaseType) {
        case MADDatabaseTypeSqlite3:
            result = [[MTDatabaseSqlite3 alloc] init];
            break;
            
        default:
            NSAssert(NO, @"Not proper type of database connection. Use Sqlite3.");
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

- (id <MTDatabaseProtocol>)delegate {
    return [super delegate];
}

@end
*/
