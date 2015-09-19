//
//  MysqlServer.m
//  mysql_connector
//
//  Created by Karl Kraft on 3/19/11.
//  Copyright 2011-2012 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlServer.h"
#import "mysql.h"

@implementation MysqlServer

@synthesize host,user,password,schema;
@synthesize port,flags,connectionTimeout;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.host = @"localhost";
        self.user = @"username";
        self.password = @"password";
        self.schema = @"test";
        self.port = 3306;
        self.flags = CLIENT_FOUND_ROWS;
        self.connectionTimeout = 30;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MysqlServer: %@:%d as user %@", host, port, user];
}

@end
