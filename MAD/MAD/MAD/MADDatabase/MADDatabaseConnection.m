//
//  MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabaseConnection.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "RptqDatabaseCredentals+MADDatabaseConnection.h"

@class RptqDatabaseCredentals;

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
            NSAssert(NO, @"Unknown database type");
            break;
    }

    
    return dbConnection;
}

+ (instancetype)newDatabaseConnectionForObject:(id)connectionObject {
    
    id resultCredentals = nil;
    
    if ([connectionObject isKindOfClass:[RptqDatabaseCredentals class]]) {
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

+ (instancetype)newDatabaseConnectionWithCredentals:(RptqDatabaseCredentals *)credentals {

    id dbConnection = nil;
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
            NSAssert(NO, @"Unknown database type");
            break;
    }
    
    return dbConnection;

}

+ (NSString *)Identifier {
    NSAssert(NO, @"This is a factory class.  Don't call this.");
    return nil;
}

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
            NSAssert(NO, @"Unknown database type");
            break;
    }
    return identifier;
    
}

@end
