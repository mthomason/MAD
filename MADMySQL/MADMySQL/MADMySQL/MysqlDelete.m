//
//  MysqlDelete.m
//  mysql_connector
//
//  Created by Karl Kraft on 9/28/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlDelete.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import <mysql.h>

@implementation MysqlDelete

+ (MysqlDelete *)deleteWithConnection:(MysqlConnection *)aConnection {

    if (!aConnection) {
        [MysqlException raiseConnection:nil withFormat:@"Connection is nil"];
    }
    
    MysqlDelete *newObject=[[self alloc] init];
    newObject->connection = aConnection;
    newObject->_tableName=nil;
    newObject->_qualifier=nil;
    return newObject;
}


- (NSString *)command {
    NSString *cmd = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", _tableName, _qualifier];
    return cmd;
}


- (void)execute {
    @synchronized (connection) {
        if (!_tableName) {
            [MysqlException raiseConnection:connection withFormat:@"Delete is missing table name"];
        }
        if (!_qualifier) {
            [MysqlException raiseConnection:connection withFormat:@"Delete is unqualified. Use TRUNCATE to wipe out tables"];
        }
        
        NSString *cmd = [self command];
        if (mysql_query(connection.connection, cmd.UTF8String)) {
            [MysqlException raiseConnection: connection
                                 withFormat: @"Could not perform mysql update %@ #%d:%s", cmd, mysql_errno(connection.connection), mysql_error(connection.connection)];
        } else {
            unsigned long long rowCount = mysql_affected_rows(connection.connection);
            _affectedRows = @(rowCount);
            MysqlLog(@"%@ rows affected by %@",affectedRows,cmd);
        }
    }
}

@end
