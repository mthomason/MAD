//
//  MysqlTruncate.m
//  mysql_connector
//
//  Created by Bill Allen on 8/22/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlTruncate.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import <mysql.h>

@implementation MysqlTruncate

@synthesize tableName;

+ (MysqlTruncate *)truncateWithConnection:(MysqlConnection *)aConnection {
    MysqlTruncate *t = [[MysqlTruncate alloc] init];
    t->connection = aConnection;
    return t;
}

+ (MysqlTruncate *)truncateWithConnection:(MysqlConnection *)aConnection forTable:(NSString *)aTableName {
    MysqlTruncate *t = [[MysqlTruncate alloc] init];
    t->connection = aConnection;
    t.tableName = aTableName;
    return t;
}

- (void)execute {
    @synchronized (connection) {
        if (!tableName) {
            [MysqlException raiseConnection:connection withFormat:@"Truncate is missing table name"];
        }
        NSString *truncate = [[NSString alloc] initWithFormat:@"truncate %@", self.tableName];
        if (mysql_query(connection.connection, truncate.UTF8String)) {
            [MysqlException raiseConnection:connection
                                 withFormat:@"Could not truncate table %@ - #%d:%s",tableName,mysql_errno(connection.connection), mysql_error(connection.connection)];
        }
    }
}

@end
