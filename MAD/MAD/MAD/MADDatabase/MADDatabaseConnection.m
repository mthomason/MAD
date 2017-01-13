//
//  MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabaseConnection.h"

#import <Foundation/NSURL.h>

#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "RptqUserCredentals+MADDatabaseConnection.h"

@class RptqUserCredentals;

@implementation MADDatabaseConnection

@dynamic databaseType;
@dynamic requiresCredientals;
@dynamic connectionString;
@dynamic identifier;

+ (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
                                         host:(NSString *)host
                                     database:(NSString *)database
                                         port:(NSInteger)port {

    id dbConnection;
    
    switch (databaseType) {
        case MADDatabaseTypeSqlite3:
            dbConnection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:nil];

            break;
            
        case MADDatabaseTypeTDS:
            dbConnection = [[MTDatabaseConnectionSqlServer alloc] initWithHost: host
                                                                        server: host
                                                                      database: database
                                                                       andPort: port];
            
            break;
            
        case MADDatabaseTypeMySQL:
            dbConnection = [[MTDatabaseConnectionMySql alloc] initWithHost: host
                                                                  database: database
                                                                   andPort: port];
            break;
            
        default:
            break;
    }

    
    return dbConnection;
}

+ (instancetype)newDatabaseConnectionForObject:(id)connectionObject {
    
    id resultCredentals = nil;
    
    if ([connectionObject isKindOfClass:[RptqUserCredentals class]]) {
        resultCredentals = [self newDatabaseConnectionWithCredentals:connectionObject];
        
    } else if ([connectionObject isKindOfClass:[NSURL class]]) {
        resultCredentals = [self newDatabaseConnectionForUrl:connectionObject];
    }
    return resultCredentals;
}

+ (instancetype)newDatabaseConnectionForUrl:(NSURL *)url {
    id dbConnection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:url];
    return dbConnection;
}

+ (instancetype)newDatabaseConnectionWithCredentals:(RptqUserCredentals *)credentals {

    id dbConnection = nil;
    RptqDatabase *database = credentals.inDatabase;
    switch (credentals.databaseType) {
        case MADDatabaseTypeSqlite3:
            dbConnection = [MTDatabaseConnectionSqlite3 newDatabaseConnectionWithCredentals:credentals];
            
            break;
            
        case MADDatabaseTypeTDS:
            dbConnection = [MTDatabaseConnectionSqlServer newDatabaseConnectionWithCredentals:credentals];
            
            break;
            
        case MADDatabaseTypeMySQL:
            dbConnection = [MTDatabaseConnectionMySql newDatabaseConnectionWithCredentals:credentals];
            break;
            
        default:
            break;
    }
    
    return dbConnection;

}

+ (NSString *)Identifier { return nil; }

+ (NSString *)Identifier:(MADDatabaseType)databaseType {
    id identifier = nil;
    
    switch (databaseType) {
        case MADDatabaseTypeSqlite3:
            identifier = [MTDatabaseConnectionSqlite3 Identifier];
            
            break;
            
        case MADDatabaseTypeTDS:
            identifier = [MTDatabaseConnectionSqlServer Identifier];
            
            break;
            
        case MADDatabaseTypeMySQL:
            identifier = [MTDatabaseConnectionMySql Identifier];
            break;
            
        default:
            break;
    }
    return identifier;
    
}

@end
