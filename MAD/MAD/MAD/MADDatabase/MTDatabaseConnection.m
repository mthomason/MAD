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
#import "MADConstants.h"
#import "RptqUserCredentals.h"
#import "MTDatabase.h"
#import "MADConstants.h"
#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"
#import "MTQuery.h"
//#import <MADFoundation/MADApplicationProtocol.h>
//#import <MADFoundation/MADAppDelegate.h>
//#import <MADFoundation/UIApplication+MADAppDelegate.h>
#import "MTQueryTest.h"

NSString * const MADIdentifierDatabaseMySQL     = @"MySQL";
NSString * const MADIdentifierDatabaseTDS       = @"TDS";
NSString * const MADIdentifierDatabaseSqlite3   = @"Sqlite 3";

NSString * const MADStringEmpty = @"";

@interface MTDatabaseConnection ()

@property (nonatomic, strong) NSString *internalServer;

@end

@implementation MTDatabaseConnection


- (void)setServer:(NSString *)server {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *internalServer = [server stringByTrimmingCharactersInSet: whitespace];
    self.internalServer = internalServer;
}

- (NSString *)server {
    return self.internalServer;
}

- (NSString *)IPAddressOrServer {
    NSString *address = [BDHost addressForHostname:self.server];
    return address == nil ? self.server : [NSString stringWithString:address];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self nullValues];
    }
    return self;
}

+ (instancetype)databaseConnectionFactoryWithType:(NSString *)typeIdentifier
                                             host:(NSString *)host
                                         database:(NSString *)database
                                             port:(NSInteger)port NS_RETURNS_RETAINED {
    
    id result = [self databaseConnectionFactoryEmpty:typeIdentifier];
    
    NSString *h   = [NSString stringWithString: host];
    ((MTDatabaseConnection *) result).server = h;
    
    NSString *d = [NSString stringWithString: database];
    ((MTDatabaseConnection *) result).database = d;
    
    ((MTDatabaseConnection *) result).port = port;
    
    return result;
}

+ (instancetype)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier NS_RETURNS_RETAINED {
    
    id resultCredentals = nil;
    
    if ([[MTDatabaseConnectionMySql identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: MADStringEmpty
                                                                  database: MADStringEmpty
                                                                   andPort: 3306];
        
    } else if ([[MTDatabaseConnectionSqlServer identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: MADStringEmpty
                                                                        server: MADStringEmpty
                                                                      database: MADStringEmpty
                                                                       andPort: 1433];
        
    } else if ([[MTDatabaseConnectionSqlite3 identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
        
    }
    
    return resultCredentals;

}

+ (instancetype)databaseConnectionFactory:(id)connectionObject NS_RETURNS_RETAINED {
    
    id resultCredentals = nil;
    
    
    if ([connectionObject isKindOfClass:[RptqUserCredentals class]]) {
        
        RptqUserCredentals *credentals = (RptqUserCredentals *)connectionObject;
        NSString *mysqlConnectionId = [MTDatabaseConnectionMySql identifier];
        
        if ([credentals.database_driver_type isEqualToString:mysqlConnectionId]) {
            
            resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: credentals.mysql_host
                                                                      database: credentals.mysql_database
                                                                       andPort: credentals.mysql_port.integerValue];
            
        } else if ([credentals.database_driver_type isEqualToString:[MTDatabaseConnectionSqlServer identifier]]) {
            
            resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: credentals.tds_host
                                                                            server: credentals.tds_server
                                                                          database: credentals.tds_database
                                                                           andPort: credentals.tds_port.integerValue];
            
        } else if ([credentals.database_driver_type isEqualToString:[MTDatabaseConnectionSqlite3 identifier]]) {
            
            NSString *databaseFilename = credentals.mysql_database;
            // FIXME: When we start using Sqlite3 for users to make there own, we will also have to search
            //          the users documents directory.  Right now, only chinook.sqlite3 should be in the sqlite3 files types.
            //          Also hacked as fuck, because I'm using the mysql storage place to do this, but fuck it!
            
            NSURL *appSupportDirectory = [[NSFileManager defaultManager] localApplicationSupportDirectoryForGroupIdentifier:MADIdentifierGroup];
            NSURL *dbUrl = [appSupportDirectory URLByAppendingPathComponent:databaseFilename isDirectory:NO];
            
            NSURL *databaseUrl = [NSURL fileURLWithPath:dbUrl.path];
            
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
    NSString * __autoreleasing connectionString = [NSString stringWithFormat:@"(%@)[%@:%ld]%@", self.databaseTypeIdentifier, self.server,  (long)self.port, self.database];
    return connectionString;
}

- (bool)testConnectionWithErrors:(NSArray * __autoreleasing *)errors {
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: self];
    NSError * __autoreleasing error = NULL;
    bool success = [queryTest.database executeQuery:queryTest withError:&error];
    if (!success && errors == NULL) {
        *errors = error ? [queryTest.database.errors arrayByAddingObject:error] : [NSArray arrayWithArray:queryTest.database.errors];
    }
    return success;
}

- (void)testConnection:(void(^)(BOOL success, NSArray *errors))completion {
    
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: self];
    NSError * __autoreleasing error = NULL;
    bool success = [queryTest.database executeQuery:queryTest withError:&error];
    NSArray *displayErrors = error ? [queryTest.database.errors arrayByAddingObject:error] : [NSArray arrayWithArray:queryTest.database.errors];
    completion(success, displayErrors);

}

@end
