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

@interface MTDatabaseConnectionMySql ()

    @property (nonatomic, readwrite, copy)      NSString  *database;
    @property (nonatomic, readwrite, copy)      NSString  *internalServer;
    @property (nonatomic, readwrite, assign)    NSInteger port;

@end

@implementation MTDatabaseConnectionMySql

- (instancetype)initWithHost:(NSString *)host database:(NSString *)database andPort:(NSInteger)port {
    if (self = [super init]) {
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *internalServer = [host stringByTrimmingCharactersInSet: whitespace];
        _internalServer = internalServer.copy;
        _database = database.copy;
        _port = port;
        self.databaseTypeIdentifier = [self identifier];
    }
    return self;
}

- (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
}

- (NSString *)connectionString {
    NSString * __autoreleasing connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%ld]%@", self.databaseTypeIdentifier, self.server,  (long)self.port, self.database];
    return connectionString;
}

- (NSInteger)port { return _port; }

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
    NSString * __autoreleasing internalServer = self.internalServer.copy;
    return internalServer;
}

@end
