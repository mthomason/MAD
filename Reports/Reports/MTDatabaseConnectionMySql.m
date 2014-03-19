//
//  MTDatabaseConnectionMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseMySql.h"

@implementation MTDatabaseConnectionMySql

- (id)initWithHost:(NSString *)host database:(NSString *)database andPort:(NSInteger)port {
    self = [super init];
    if (self) {
        [self setServer: host];
        [self setDatabase: database];
        [self setPort: port];
        [self setDatabaseTypeIdentifier: [MTDatabaseMySql identifier]];
    }
    return self;
}

@end
