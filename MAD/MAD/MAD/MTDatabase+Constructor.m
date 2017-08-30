//
//  MTDatabase+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase+Constructor.h"
#import <MADAPI/MADDatabaseConnection.h>
#import "MTDatabaseMySql.h"
#import <MADSqlite3/MTDatabaseSqlite3.h>
#import "MTDatabaseSqlServer.h"

@class MTDatabaseSqlite3;

@implementation MTDatabase (Comparson)

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {
    
    id result = nil;
    
    switch (connection.databaseType) {
        case MADDatabaseTypeSqlite3:
            result = [[MTDatabaseSqlite3 alloc] init];
            
            break;
            
        case MADDatabaseTypeTDS:
            result = [[MTDatabaseSqlServer alloc] init];
            
            break;
            
        case MADDatabaseTypeMySQL:
            result = [[MTDatabaseMySql alloc] init];
            
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

- (void)openDatabase {
    
}

@end
