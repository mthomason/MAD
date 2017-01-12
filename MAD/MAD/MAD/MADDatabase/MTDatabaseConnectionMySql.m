//
//  MTDatabaseConnectionMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnectionMySql.h"
#import <Foundation/NSCharacterSet.h>
#import "RptqUserCredentals.h"

@implementation MTDatabaseConnectionMySql

@synthesize database = _database;
@synthesize server = _server;
@synthesize host = _host;
@synthesize port = _port;
@synthesize connectionString = _connectionString;
@synthesize databaseType = _databaseType;

@dynamic identifier;

+ (instancetype)newDatabaseConnectionWithCredentals:(RptqUserCredentals *)credentals {
    
    id dbConnection;
    dbConnection = [[self alloc] initWithHost: credentals.mysql_host
                                     database: credentals.mysql_database
                                      andPort: credentals.mysql_port.integerValue];
    
    return dbConnection;
    
}

- (instancetype)initWithHost:(NSString *)host
                    database:(NSString *)database
                     andPort:(NSInteger)port {
    if (self = [super init]) {
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *server = [host stringByTrimmingCharactersInSet: whitespace];
        _server = server.copy;
        _host = host.copy;
        _database = database.copy;
        _port = port;
        _databaseType = MADDatabaseCategoryMySQL;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithHost: _host
                                                     database: _database
                                                      andPort: _port];
    return copy;
}

- (NSString *)identifier {
    return [[self class] Identifier];
}

+ (NSString *)Identifier {
    return @"MySQL";
}

- (NSString *)connectionString {
    if (!_connectionString) {
        _connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%ld]%@",
                                self.identifier,
                                self.server,
                                (long)_port,
                                _database];
    }
    return _connectionString;
}

- (BOOL)requiresCredientals {
    return YES;
}

@end
