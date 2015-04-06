//
//  MNSDatabaseConnection.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnection.h"
#import "RptqUserCredentals.h"
#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "NSFileManager+Common.h"
#import "MTQuery.h"
#import "NSString+Extras.h"

NSString * const MADIdentifierDatabaseMySQL     = @"MySQL";
NSString * const MADIdentifierDatabaseTDS       = @"TDS";
NSString * const MADIdentifierDatabaseSqlite3   = @"Sqlite 3";

@interface MTDatabaseConnection ()

@end

@implementation MTDatabaseConnection

- (instancetype)init {
    self = [super init];
    if (self) {
        [self nullValues];
    }
    return self;
}

+ (instancetype)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier {
    
    id resultCredentals = nil;
    
    if ([[MTDatabaseConnectionMySql identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: [NSString empty]
                                                                  database: [NSString empty]
                                                                   andPort: 3306];
        
    } else if ([[MTDatabaseConnectionSqlServer identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: [NSString empty]
                                                                        server: [NSString empty]
                                                                      database: [NSString empty]
                                                                       andPort: 1433];
        
    } else if ([[MTDatabaseConnectionSqlite3 identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
        
    }
    
    return resultCredentals;

}

+ (instancetype)databaseConnectionFactory:(id)connectionObject {
    
    id resultCredentals = nil;
    
    
    if ([connectionObject isKindOfClass:[RptqUserCredentals class]]) {
        RptqUserCredentals *credentals = (RptqUserCredentals *)connectionObject;
        
        NSString *mysqlConnectionId = [MTDatabaseConnectionMySql identifier];
        if ([[credentals database_driver_type] isEqualToString:mysqlConnectionId]) {
            
            resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: credentals.mysql_host
                                                                      database: credentals.mysql_database
                                                                       andPort: credentals.mysql_port.integerValue];
            
        } else if ([[credentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlServer identifier]]) {
            
            resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: credentals.tds_host
                                                                            server: credentals.tds_server
                                                                          database: credentals.tds_database
                                                                           andPort: credentals.tds_port.integerValue];
            
        } else if ([[credentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlite3 identifier]]) {
            
            NSString *databaseFilename = [credentals mysql_database];
            // FIXME: When we start using Sqlite3 for users to make there own, we will also have to search
            //          the users documents directory.  Right now, only chinook.sqlite3 should be in the sqlite3 files types.
            //          Also hacked as fuck, because I'm using the mysql storage place to do this, but fuck it!
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *appSupportDirectory = [fileManager localApplicationSupportDirectory];
            NSURL *dbUrl = [appSupportDirectory URLByAppendingPathComponent:databaseFilename isDirectory:NO];
            NSString *databasePath = [dbUrl path];
            NSURL *databaseUrl = [NSURL fileURLWithPath:databasePath];
            resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:databaseUrl];
            
        }

    } else if ([connectionObject isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)connectionObject;
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:url];
    }
    
    
    return resultCredentals;
}

- (NSString *)appname {
    return @"mad";
}

- (void)nullValues {
    [self setDatabaseTypeIdentifier: nil];
    [self setDatabaseUrl: nil];
    [self setServer: nil];
    [self setDatabase: nil];
    [self setHost: nil];
    [self setUsername: nil];
    [self setPassword: nil];
    [self setPort: 0];
}

- (NSString *)identifier {
    return [MTDatabaseConnection identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

- (NSString *)connectionString {
    return [NSString stringWithFormat:@"(%@)[%@:%ld]%@", self.databaseTypeIdentifier, self.server,  (long)self.port, self.database];
}

- (void)testConnection:(void(^)(BOOL success, NSError *error))completion {
    MTQuery *queryTest = [[MTQuery alloc] initWithQueryType: MTQueryTypeConnectionTest
                                                     object: self];
    [queryTest performQuery:^(BOOL success, NSError *error) {
        completion(success, error);
    }];
}

@end
