//
//  MTDatabaseConnectionSqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnectionSqlServer.h"

@implementation MTDatabaseConnectionSqlServer

- (id)initWithHost:(NSString *)host
            server:(NSString *)server
          database:(NSString *)database
           andPort:(NSInteger)port {
    
    self = [super init];
    if (self) {
        [self setHost: host];
        [self setServer: server];
        [self setDatabase: database];
        [self setPort: port];
        [self setDatabaseTypeIdentifier: [MTDatabaseConnectionSqlServer identifier]];
    }
    return self;
}

- (NSString *)identifier {
    return [MTDatabaseConnectionSqlServer identifier];
}

+ (NSString *)identifier {
    return @"TDS";
}

@end
