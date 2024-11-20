//
//  MADDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionSqlite3.h"
#import <Foundation/NSURL.h>

#import <MADFoundation/MADURL.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADAPI/MADConnectionsPropertiesProtocol.h>

@implementation MADDatabaseConnectionSqlite3

@synthesize databaseUrl = _databaseUrl;
@synthesize connectionString = _connectionString;
@synthesize databaseType = _databaseType;

@dynamic identifier;

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {

    id dbConnection;
    //dbConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
    
    NSString *databaseFilename = credentals.database.copy;
    
    // FIXME: When we start using Sqlite3 for users to make there own, we will also have to search
    //          the users documents directory.  Right now, only chinook.sqlite3 should be in the sqlite3 files types.
    //          Also hacked as fuck, because I'm using the mysql storage place to do this, but fuck it!
    
    MADURL *appSupportDirectory;
    id groupIdentifier = [MADApplication groupIdentifier];
    appSupportDirectory = [MADURL newURLLocalApplicationSupportDirectoryForGroupID: groupIdentifier];
    
    NSURL *dbUrl = [appSupportDirectory URLByAppendingPathComponent: databaseFilename
                                                        isDirectory: NO];
    NSString *path = dbUrl.path.copy;
    NSURL *databaseUrl = path != nil ? [[NSURL alloc] initFileURLWithPath: path] : nil;
    dbConnection = [[self alloc] initWithUrl:databaseUrl];
    return dbConnection;
    
}

- (instancetype)initWithUrl:(NSURL *)url {
    if (self = [super init]) {
        _databaseUrl = url.copy;
        _databaseType = MADDatabaseTypeSqlite3;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithUrl:self.databaseUrl];
    return copy;
}

- (NSString *)connectionString {
    if (!_connectionString) {
        _connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@]",
                             self.identifier, self.databaseUrl];
    }
    return _connectionString;
;
}

- (NSString *)identifier {
    return [[self class] Identifier];
}

+ (NSString *)Identifier {
    return @"Sqlite 3";
}

- (BOOL)requiresCredientals {
    return NO;
}

@end
