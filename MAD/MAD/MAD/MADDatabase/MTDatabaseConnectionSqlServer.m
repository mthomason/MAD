//
//  MTDatabaseConnectionSqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnectionSqlServer.h"
#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>

#import "RptqUserCredentals.h"

@implementation MTDatabaseConnectionSqlServer

@synthesize database = _database;
@synthesize server = _server;
@synthesize host = _host;
@synthesize port = _port;
@synthesize connectionString = _connectionString;
@synthesize databaseType = _databaseType;

@dynamic identifier;

+ (instancetype)newDatabaseConnectionWithCredentals:(RptqUserCredentals *)credentals {
    
    id dbConnection = nil;
    
    dbConnection = [[self alloc] initWithHost: credentals.tds_host
                                       server: credentals.tds_server
                                     database: credentals.tds_database
                                      andPort: credentals.tds_port.integerValue];
    
    return dbConnection;
    
}

- (instancetype)initWithHost:(NSString *)host
                      server:(NSString *)server
                    database:(NSString *)database
                     andPort:(NSInteger)port {
    
    if (self = [super init]) {
        _host = host.copy;
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *internalServer = [server stringByTrimmingCharactersInSet: whitespace];
        _server = internalServer.copy;
        _database = database.copy;
        _port = port;
        _databaseType = MADDatabaseCategoryTDS;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithHost:self.host server:self.server
                                                     database:self.database andPort:self.port];
    return copy;
}

- (NSString *)connectionString {
    if (!_connectionString) {
        _connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%@:%ld]%@",
                             self.identifier, self.host,
                             self.server, (long)self.port, self.database];
    }
    return _connectionString;
}

- (NSString *)identifier {
    return [self.class Identifier];
}

+ (NSString *)Identifier {
    return @"TDS";
}

- (BOOL)requiresCredientals {
    return YES;
}

@end
