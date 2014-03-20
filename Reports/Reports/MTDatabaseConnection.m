//
//  MNSDatabaseConnection.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnection.h"
#import "MTApplicationInstance.h"
#import "RptqUserCredentals.h"
#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "NSFileManager+Common.h"

@implementation MTDatabaseConnection

- (id)init {
    self = [super init];
    if (self) {
        [self nullValues];
    }
    return self;
}

+ (id)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier {
    
    id resultCredentals = nil;
    
    if ([[MTDatabaseConnectionMySql identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: @""
                                                                  database: @""
                                                                   andPort: 3306];
        
    } else if ([[MTDatabaseConnectionSqlServer identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: @""
                                                                        server: @""
                                                                      database: @""
                                                                       andPort: 1433];
        
    } else if ([[MTDatabaseConnectionSqlite3 identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
        
    }
    
    return [resultCredentals autorelease];

}

+ (id)databaseConnectionFactory:(RptqUserCredentals *)credentals {
    
    id resultCredentals = nil;
    
    if ([[credentals database_driver_type] isEqualToString:[MTDatabaseConnectionMySql identifier]]) {
        
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
        NSURL *appSupportDirectory = [NSFileManager applicationSupportDirectory];
        NSURL *dbUrl = [appSupportDirectory URLByAppendingPathComponent:databaseFilename isDirectory:NO];
        NSString *databasePath = [dbUrl path];
        NSURL *databaseUrl = [NSURL fileURLWithPath:databasePath];
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:databaseUrl];

    }
    
    return [resultCredentals autorelease];
}

- (NSString *)appname {
    return [MTApplicationInstance bundleDisplayName];
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

@end
