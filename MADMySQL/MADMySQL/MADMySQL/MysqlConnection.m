//
//  MysqlConnection.m
//  mysql_connector
//
//  Created by Karl Kraft on 5/21/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlConnection.h"
#import "MysqlServer.h"

#import "MysqlCommitException.h"
#import "MysqlRollbackException.h"

#import "mysql.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSError.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSThread.h>
#import <string.h>


@interface MysqlConnection ()

    @property (readonly) MYSQL *connection;

@end

@implementation MysqlConnection

@synthesize transactionsEnabled, server;

- (unsigned int)errorNumber {
    return mysql_errno(self.connection);
}

- (const char *)errorText {
    return mysql_error(self.connection);
}

+ (MysqlConnection *)connectToServer:(MysqlServer *)server {
    MysqlConnection *newObject = [[self alloc] init];
    newObject->_connection= calloc(1,sizeof(MYSQL));
    mysql_init(newObject->_connection);

    // FIXME: Add timeout feature.
    //unsigned int timeout=server.connectionTimeout;
    //mysql_options(newObject->_connection,MYSQL_OPT_CONNECT_TIMEOUT, &timeout);
    
    #ifdef DEBUG
        NSLog(@"Connecting to %@",server);
    #endif
    
    if (!mysql_real_connect(newObject->_connection,
                            [server.host UTF8String],
                            [server.user UTF8String],
                            [server.password UTF8String],
                            [server.schema UTF8String],
                            server.port,  // default port
                            NULL,  // default socket
                            server.flags)) {
        #ifdef DEBUG
            NSLog(@"Failed to connect: Error: %s\n",mysql_error(NULL));
        #endif
        return nil;
    } else {
        #ifdef DEBUG
            NSLog(@"Connected to %@",server);
        #endif
    }
    if (!mysql_set_character_set(newObject->_connection, "utf8")) {
        #ifdef DEBUG
            NSLog(@"Client character set: %s\n", mysql_character_set_name(newObject->_connection));
        #endif

    }
    newObject->server = server;
    return newObject;
}

+ (MysqlConnection *)connectToServer:(MysqlServer *)server error:(NSError * __autoreleasing *)error {

    MysqlConnection *newObject = [[self alloc] init];
    newObject->_connection= calloc(1, sizeof(MYSQL));
    mysql_init(newObject->_connection);
    
    // FIXME: Add timeout feature.
    //unsigned int timeout=server.connectionTimeout;
    //int options = mysql_options(newObject->_connection, MYSQL_OPT_CONNECT_TIMEOUT, &timeout);
    
    MYSQL *connectionHandle =     newObject->_connection;
    const char *host =      server.host.UTF8String;
    const char *password =  server.password.UTF8String;
    const char *user =      server.user.UTF8String;
    const char *schema =    server.schema.UTF8String;
    unsigned int port =     server.port;
    
    mysql_real_connect(connectionHandle, host, user, password, schema, port,
                       NULL,  /* default socket */ server.flags);

    if (!connectionHandle) {
        NSString *errorDescription;
        errorDescription = [[NSString alloc] initWithFormat:@"%s", mysql_error(connectionHandle)];
        unsigned int errorCode = mysql_errno(connectionHandle);
        if ([errorDescription length] <= 0) {
            errorDescription = NSLocalizedString(@"Failed to connect", @"Failed to connect");
        }
        if (errorCode == 0) {
            errorCode = 101;
        }
        if (error != NULL) {
            NSDictionary *userInfo;
            userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                            errorDescription, NSLocalizedDescriptionKey, nil];
            *error = [NSError errorWithDomain: @"MTDatabaseMySql"
                                         code: (NSInteger)errorCode
                                     userInfo: userInfo];
        }
        return nil;
    }
    #ifdef DEBUG
        if (!mysql_set_character_set(connectionHandle, "utf8")) {
            NSLog(@"Client character set: %s\n", mysql_character_set_name(connectionHandle));
        }
    #endif
    newObject->server = server;
    return newObject;
}

+ (MysqlConnection *)connectToServers:(NSArray *)arrayOfServers {
    for (MysqlServer *server in arrayOfServers) {
        MysqlConnection *aConnection=[self connectToServer:server];
        if (aConnection) return aConnection;
    }
    return nil;
}


- (void)enableStrictSql {
    @synchronized (self) {
        if (mysql_query(_connection, "set sql_mode=strict_all_tables")) {
            [MysqlException raiseConnection:self
                                 withFormat:@"Could not set sql_mode #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
        }
    }
}

- (void)enableTriggers {
    @synchronized (self) {
        if (mysql_query(_connection, "set @DISABLE_TRIGGERS = NULL")) {
            [MysqlException raiseConnection:self
                                 withFormat:@"Could not enable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
        }
    }
}

- (void)disableTriggers {
    @synchronized (self) {
        if (mysql_query(_connection, "set @DISABLE_TRIGGERS = 1")) {
            [MysqlException raiseConnection:self
                                 withFormat:@"Could not disable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
        }
    }
}

- (void)enableTransactions
{
    @synchronized (self) {
        transactionsEnabled=YES;
        mysql_autocommit(_connection, 0);
    }
}

- (void)disableTransactions
{
    @synchronized (self) {
        transactionsEnabled=NO;
        mysql_autocommit(_connection, 1);
    }
}

- (void)commitTransaction
{
    @synchronized (self) {
        if (mysql_commit(_connection)) {
            [MysqlCommitException raiseConnection:self withFormat:@"Transaction commit failed (%s)",mysql_error(_connection)];
        }
    }
}

- (void)rollbackTransaction
{
    @synchronized (self) {
        if (mysql_rollback(_connection)) {
            [MysqlRollbackException raiseConnection:self withFormat:@"Transaction rollback failed (%s)",mysql_error(_connection)];
        }
    }
}

- (void)sendIdle  __attribute__ ((noreturn))
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"Mysql Idle Thread"];
        while (true) {
            [NSThread sleepForTimeInterval:20.0];
            @synchronized (self) {
                mysql_query(_connection, "select 'MysqlConnect:idleTmer'");
                MYSQL_RES     *theResults = mysql_use_result(_connection);
                mysql_free_result(theResults);
            }
        }
    }
}

- (void)startIdle
{
    [self performSelectorInBackground: @selector(sendIdle)
                           withObject: nil];
}



- (void)dealloc {
    mysql_close(_connection);
    free(_connection);
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@/%@/%@/%@",[super description],server.host,server.schema,server.user,server.password];
}

@end
