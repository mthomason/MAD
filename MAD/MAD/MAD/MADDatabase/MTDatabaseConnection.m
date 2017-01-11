//
//  MTDatabaseConnection.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnection.h"

#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

#import <MADCocoaExtensions/BDHost.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADFoundation/MADURL.h>
#import <MADFileManager/MADFileUtilities.h>

#import "MADConstants.h"
#import "RptqUserCredentals.h"
#import "MTDatabase.h"
#import "MADConstants.h"
#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"
#import "MTQuery.h"
#import "MTQueryTest.h"


NSString * const MADIdentifierDatabaseMySQL     = @"MySQL";
NSString * const MADIdentifierDatabaseTDS       = @"TDS";
NSString * const MADIdentifierDatabaseSqlite3   = @"Sqlite 3";
NSString * const MADStringEmpty = @"";

@interface MTDatabaseConnection ()

@end

@implementation MTDatabaseConnection

+ (NSString *)IPAddressForServer:(NSString *)server {
    NSString *address = [BDHost addressForHostname:server];
    return address == nil ? server : [NSString stringWithString:address];
}

- (instancetype)init {
    if (self = [super init]) {
        _databaseTypeIdentifier = nil;
    }
    return self;
}

+ (instancetype)newDatabaseConnectionWithType:(NSString *)typeIdentifier
                                         host:(NSString *)host
                                     database:(NSString *)database
                                         port:(NSInteger)port NS_RETURNS_RETAINED {
    
    id resultCredentals = nil;
    
    if ([[MTDatabaseConnectionMySql identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionMySql alloc] initWithHost: host
                                                                  database: database
                                                                   andPort: port];
        
    } else if ([[MTDatabaseConnectionSqlServer identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlServer alloc] initWithHost: host
                                                                        server: host
                                                                      database: database
                                                                       andPort: port];
        
    } else if ([[MTDatabaseConnectionSqlite3 identifier] isEqualToString:typeIdentifier]) {
        
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
        
    }
    
    return resultCredentals;
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

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    id databaseTypeIdentifier = [self.databaseTypeIdentifier copyWithZone:zone];
    ((MTDatabaseConnection *)copy).databaseTypeIdentifier = databaseTypeIdentifier;
    return copy;
}

// Currently only returns SQLite3 type.
+ (instancetype)newDatabaseConnectionForUrl:(NSURL *)url {
    NSURL *sqlite_url = url.copy;
    id resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:sqlite_url];
    return resultCredentals;
}

+ (instancetype)newDatabaseConnectionForUserCredentals:(RptqUserCredentals *)credentals {
    id resultCredentals = nil;
    
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
        
        MADURL *appSupportDirectory;
        MADAppDelegate appDelegate = [MADApplication AppDelegate];
        id groupIdentifier = [appDelegate groupIdentifier].copy;
        appSupportDirectory = [MADURL newURLLocalApplicationSupportDirectoryForGroupID: groupIdentifier];
        
        NSURL *dbUrl = [appSupportDirectory URLByAppendingPathComponent: databaseFilename
                                                            isDirectory: NO];
        NSString *path = dbUrl.path.copy;
        NSURL *databaseUrl = path != nil ? [[NSURL alloc] initFileURLWithPath: path] : nil;
        resultCredentals = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:databaseUrl];
        
    }
    return resultCredentals;
}

+ (instancetype)newDatabaseConnectionForObject:(id)connectionObject {
    
    id resultCredentals = nil;
    
    if ([connectionObject isKindOfClass:[RptqUserCredentals class]]) {
        resultCredentals = [self newDatabaseConnectionForUserCredentals:connectionObject];

    } else if ([connectionObject isKindOfClass:[NSURL class]]) {
        resultCredentals = [self newDatabaseConnectionForUrl:connectionObject];
    }
    
    
    return resultCredentals;
}

- (NSString *)appname { return @"mad"; }

- (NSString *)identifier {
    return [MTDatabaseConnection identifier];
}

+ (NSString *)identifier {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MTDatabaseConnection; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)connectionString {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MTDatabaseConnection; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSURL *)databaseUrl { return nil; }

- (NSString *)database { return nil; }

- (NSString *)server { return nil; }

- (NSInteger)port { return 0; }

- (BOOL)requiresCredientals {
    return ![self.databaseTypeIdentifier isEqualToString:MADIdentifierDatabaseSqlite3];
}

@end
