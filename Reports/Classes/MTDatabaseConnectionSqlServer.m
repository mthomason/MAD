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

@implementation MTDatabaseConnectionSqlServer

- (instancetype)initWithHost:(NSString *)host
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
