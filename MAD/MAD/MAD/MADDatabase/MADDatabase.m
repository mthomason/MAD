//
//  MADDatabase.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabase.h"

#import "MADDatabaseConnection.h"

#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseSqlServer.h"

NSString * const MADIdentifierDatabaseMySQL     = @"MySQL";
NSString * const MADIdentifierDatabaseTDS       = @"TDS";
NSString * const MADIdentifierDatabaseSqlite3   = @"Sqlite 3";

@implementation MADDatabase

+ (instancetype)newDatabase:(MADDatabaseConnection *)databaseConnection {
    id result = nil;
    
    switch (databaseConnection.databaseType) {
        case MADDatabaseTypeMySQL:
            result = [[MTDatabaseMySql alloc] init];
            break;
            
        case MADDatabaseTypeSqlite3:
            result = [[MTDatabaseSqlite3 alloc] init];
            break;
            
        case MADDatabaseTypeTDS:
            result = [[MTDatabaseSqlServer alloc] init];
            break;
            
        default:
            break;
    }
    
    
    [result setDatabaseConnection:databaseConnection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return result;
}



@end
