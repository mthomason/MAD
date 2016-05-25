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

@interface MTDatabaseConnectionMySql ()

    @property (nonatomic, readwrite, copy)      NSString  *host;
    @property (nonatomic, readwrite, copy)      NSString  *internalServer;
    @property (nonatomic, readwrite, copy)      NSString  *database;
    @property (nonatomic, readwrite, assign)    NSInteger port;

@end

@implementation MTDatabaseConnectionMySql

- (instancetype)initWithHost:(NSString *)host database:(NSString *)database
                     andPort:(NSInteger)port {
    if (self = [super init]) {
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *internalServer = [host stringByTrimmingCharactersInSet: whitespace];
        _host = host.copy;
        _internalServer = internalServer.copy;
        _database = database.copy;
        _port = port;
        self.databaseTypeIdentifier = [self identifier];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithHost: self.host
                                                     database: self.database
                                                      andPort: self.port];
    return copy;
}

- (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
}

- (NSString *)connectionString {
    NSString *connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%ld]%@",
                                                                self.databaseTypeIdentifier,
                                                                self.server,
                                                                (long)_port,
                                                                _database];
    return connectionString;
}

- (NSInteger)port { return _port; }

- (NSString *)database {
    NSString *database = _database.copy;
    return database;
}

- (NSString *)server {
    NSString *internalServer = _internalServer.copy;
    return internalServer;
}

@end
