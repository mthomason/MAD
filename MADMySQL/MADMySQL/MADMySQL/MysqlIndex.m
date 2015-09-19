//
//  MysqlIndex.m
//  mysql_connector
//
//  Created by Bill Allen on 8/26/11.
//  Copyright 2011-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlIndex.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import "MysqlFetch.h"

@implementation MysqlIndex

@synthesize connection;

+ (MysqlIndex *)indexWithConnection:(MysqlConnection *)aConnection {
    MysqlIndex *t = [[self alloc] init];
    t->connection = aConnection;
    return t;
}

@end
