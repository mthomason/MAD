//
//  MADDatabaseConnection+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseConnection+Constructor.h"

#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>

@implementation MADDatabaseConnection (Constructor)

+ (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
                                         host:(NSString *)host
                                     database:(NSString *)database
                                         port:(NSInteger)port {

    id dbConnection;
    
    switch (databaseType) {
        case MADDatabaseTypeSqlite3:
            dbConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:nil];

            break;
            
        case MADDatabaseTypeTDS:
            dbConnection = [[MADDatabaseConnectionSQLServer alloc] initWithHost: host
                                                                        server: host
                                                                      database: database
                                                                       andPort: port];
            
            break;
            
        case MADDatabaseTypeMySQL:
            dbConnection = [[MADDatabaseConnectionMySql alloc] initWithHost: host
                                                                  database: database
                                                                   andPort: port];
            break;
            
        default:
            NSAssert(NO, @"Unknown database type");
            break;
    }

    
    return dbConnection;
}

+ (instancetype)newDatabaseConnectionForUrl:(NSURL *)url {
    id dbConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
    return dbConnection;
}

+ (instancetype)newDatabaseConnectionForObject:(id)connectionObject {
    
    id resultCredentals = nil;
    
    if ([connectionObject conformsToProtocol:@protocol(MADConnectionsPropertiesProtocol)]) {
        resultCredentals = [self newDatabaseConnection:connectionObject];
        
    } else if ([connectionObject isKindOfClass:[NSURL class]]) {
        resultCredentals = [self newDatabaseConnectionForUrl:connectionObject];
    }
    return resultCredentals;
}

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
    
    id dbConnection = nil;
    switch (credentals.databaseType) {
        case MADDatabaseTypeSqlite3:
            dbConnection = [MADDatabaseConnectionSqlite3 newDatabaseConnection:credentals];
            
            break;
            
        case MADDatabaseTypeTDS:
            dbConnection = [MADDatabaseConnectionSQLServer newDatabaseConnection:credentals];
            
            break;
            
        case MADDatabaseTypeMySQL:
            dbConnection = [MADDatabaseConnectionMySql newDatabaseConnection:credentals];
            break;
            
        default:
            NSAssert(NO, @"Unknown database type");
            break;
    }
    
    return dbConnection;
    
}

+ (NSString *)Identifier:(MADDatabaseType)databaseType {
    id identifier = nil;
    
    switch (databaseType) {
        case MADDatabaseTypeSqlite3:
            identifier = [MADDatabaseConnectionSqlite3 Identifier];
            
            break;
            
        case MADDatabaseTypeTDS:
            identifier = [MADDatabaseConnectionSQLServer Identifier];
            
            break;
            
        case MADDatabaseTypeMySQL:
            identifier = [MADDatabaseConnectionMySql Identifier];
            break;
            
        default:
            NSAssert(NO, @"Unknown database type");
            break;
    }
    return identifier;
}

@end
