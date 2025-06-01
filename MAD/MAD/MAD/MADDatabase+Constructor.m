//
//  MADDatabase+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#define INCLUDE_MYSQL 1

#import "MADDatabase+Constructor.h"
#import <MADAPI/MADDatabaseConnection.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>

@class MADDatabaseSqlite3;

@implementation MADDatabase (Comparson)

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {
    
    id result = nil;
    
    switch (connection.databaseType) {
        case MADDatabaseTypeSqlite3:
            result = [[MADDatabaseSqlite3 alloc] init];
            
            break;
            
        case MADDatabaseTypeTDS:
            result = [[MADDatabaseSQLServer alloc] init];
            
            break;
#ifdef INCLUDE_MYSQL
        case MADDatabaseTypeMySQL:
            result = [[MADDatabaseMySQL alloc] init];
            
            break;
#endif
        default:
            break;
    }
    
    [result setDatabaseConnection:connection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return result;
}

- (void)openDatabase {
    
}

@end
