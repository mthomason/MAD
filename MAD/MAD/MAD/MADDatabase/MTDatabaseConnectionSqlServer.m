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

@interface MTDatabaseConnectionSqlServer ()

    @property (nonatomic, readwrite, copy) NSString  *database;
    @property (nonatomic, readwrite, copy) NSString  *internalServer;
    @property (nonatomic, readwrite, copy) NSString  *host;
    @property (nonatomic, readwrite, assign) NSInteger port;

@end

@implementation MTDatabaseConnectionSqlServer

- (instancetype)initWithHost:(NSString *)host
                      server:(NSString *)server
                    database:(NSString *)database
                     andPort:(NSInteger)port {
    
    if (self = [super init]) {
        _host = host.copy;
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *internalServer = [server stringByTrimmingCharactersInSet: whitespace];
        _internalServer = internalServer.copy;
        _database = database.copy;
        _port = port;
        self.databaseTypeIdentifier = MADIdentifierDatabaseTDS;
    }
    return self;
}

- (NSString *)connectionString {
    NSString * __autoreleasing connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%@:%ld]%@", self.databaseTypeIdentifier, self.host, self.server,  (long)self.port, self.database];
    return connectionString;
}

- (NSString *)identifier {
    return MADIdentifierDatabaseTDS;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseTDS;
}

- (NSString *)database {
    NSString * __autoreleasing database = _database.copy;
    return database;
}

- (void)setServer:(NSString *)server {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString * __autoreleasing internalServer = [server stringByTrimmingCharactersInSet: whitespace];
    _internalServer = internalServer.copy;
}

- (NSString *)server {
    NSString * __autoreleasing internalServer = _internalServer.copy;
    return internalServer;
}

- (NSInteger)port { return _port; }

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithHost:self.host server:self.internalServer database:self.database andPort:self.port];
    return copy;
}

@end
