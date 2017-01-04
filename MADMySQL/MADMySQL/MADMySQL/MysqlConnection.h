//
//  MysqlConnection.h
//  mysql_connector
//
//  Created by Karl Kraft on 5/21/08.
//  Copyright 2008-2012 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlConnection_h
#define MAD_MysqlConnection_h

#import <Foundation/NSObject.h>

@class MysqlServer;

@interface MysqlConnection : NSObject {
    BOOL transactionsEnabled;
    MysqlServer *server;
}

    - (unsigned int)errorNumber;
    - (const char *)errorText NS_RETURNS_INNER_POINTER;

    - (void *)connection NS_RETURNS_INNER_POINTER;

    @property(readonly) BOOL transactionsEnabled;
    @property(readonly) MysqlServer *server;

    + (MysqlConnection *)connectToServers:(NSArray *)arrayOfServers;
    + (MysqlConnection *)connectToServer:(MysqlServer *)server;
    + (MysqlConnection *)connectToServer:(MysqlServer *)server error:(NSError * __autoreleasing *)error;

    - (void)enableTransactions;
    - (void)disableTransactions;
    - (void)commitTransaction;
    - (void)rollbackTransaction;

    - (void)enableStrictSql;

    - (void)enableTriggers;
    - (void)disableTriggers;

    - (void)startIdle;

    - (NSString *)mysqlEscapeString:(NSString *)string;

@end

#endif
