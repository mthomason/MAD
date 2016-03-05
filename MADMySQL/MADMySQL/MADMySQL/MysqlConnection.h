//
//  MysqlConnection.h
//  mysql_connector
//
//  Created by Karl Kraft on 5/21/08.
//  Copyright 2008-2012 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlConnection_h
#define MAD_MysqlConnection_h

#import <Foundation/Foundation.h>
#import "mysql.h"

@class MysqlServer;

@interface MysqlConnection : NSObject {
    BOOL transactionsEnabled;
    MysqlServer *server;
}

@property(readonly) MYSQL * _Null_unspecified connection;
@property(readonly) BOOL transactionsEnabled;
@property(readonly) MysqlServer * _Null_unspecified server;

+ (MysqlConnection * _Nullable)connectToServers:(NSArray * _Null_unspecified)arrayOfServers;
+ (MysqlConnection * _Null_unspecified)connectToServer:(MysqlServer * _Null_unspecified)server;
+ (MysqlConnection * _Null_unspecified)connectToServer:(MysqlServer * _Null_unspecified)server error:(NSError * _Nullable * _Nullable)error;

- (void)enableTransactions;
- (void)disableTransactions;
- (void)commitTransaction;
- (void)rollbackTransaction;

- (void)enableStrictSql;

- (void)enableTriggers;
- (void)disableTriggers;

- (void)startIdle;

@end

#endif
