//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDatabaseMySql.h"
#import "mysql.h"
#import "NSConnection.h"
#import "Constants.h"
#import <stdio.h>

@implementation NSDatabaseMySql

@synthesize username = _username;
@synthesize password = _password;
@synthesize host = _host;
@synthesize port = _port;

- (void)dealloc {
    //[_username release];
    //[_password release];
    //[_host release];
    [super dealloc];
}

- (id)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username andPassword:(NSString *)password {
    self = [super init];
    if (self) {
        [self setUsername: username];
        [self setPassword: password];
        [self setHost: host];
        [self setPort: port];
        h = [host UTF8String];
        u = [username UTF8String];
        p = [password UTF8String];
    }
    return self;
}

- (id)initWithOptions:(NSDictionary *)optons {
    self = [super init];
    if (self) {
        NSString *user = [[optons objectForKey:NSDATABASE_USERNAME] retain];
        NSString *pass = [[optons objectForKey:NSDATABASE_PASSWORD] retain];
        NSString *host = [[optons objectForKey:NSDATABASE_HOST] retain];
        
        h = [host UTF8String];
        u = [user UTF8String];
        p = [pass UTF8String];
        
        [self setUsername: user];
        [self setPassword: pass];
        [self setHost: host];
        [self setPort: [[optons objectForKey:NSDATABASE_PORT] integerValue]];
        
        [pass release];
        [host release];
        [user release];
    }
    return self;
}

- (NSArray *)tablesFor:(NSString *)database {
    
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    NSConnection *connection = [[NSConnection alloc] init];
    mysql_init(&(connection->conn));
    //long flags = MYSQL_DEFAULT_CONNECTION_FLAGS;
    mysql_real_connect(&(connection->conn), "everydayapps.com", "root", "1noniceguy", "quotationary", 3306, NULL, 0);
    
    NSString *q = @"SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ";
    char query[[q length] + 12];
    sprintf(query, "SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ", "quotationary");// (const char *)[database UTF8String]);
    NSLog(@"query %s", query);
    mysql_query(&(connection->conn), query);
    
    MYSQL_RES *result = mysql_store_result(&(connection->conn));
    NSMutableSet *mutableResult = nil;
    
    if (result) {
        int num_rows = mysql_num_rows(result);
        mutableResult = [[[NSMutableSet alloc] initWithCapacity:num_rows] autorelease];
        
        //@autoreleasepool {
        MYSQL_ROW row;
        //@autoreleasepool {
        //mysql_fetch_row(result);
        //printf("row %s", row[0]);
        while ((row = mysql_fetch_row(result))) {
            NSLog(@"Got row");
            if (row[0]) {
                NSString *name = [[NSString alloc] initWithUTF8String:row[0]];
                [resultArray addObject: name];
                if (name) {
                    [mutableResult addObject: name];
                } else {
                    NSLog(@"Not got name");
                }
                NSLog(@"row %s", row[0]);
                NSLog(@"name %@", name);
                [name release];
                
            } else {
                NSLog(@"Not got row!!!");
            }
        }
        
        
        mysql_free_result(result);
    }    
    mysql_close(&(connection->conn));
    [connection release];

    
    
    /*
    MYSQL *conn = mysql_init(NULL);
    //const char *h = [[self host] UTF8String];
    mysql_real_connect(conn, h, u, p, NULL, [self port], NULL, 0);
    NSString *q = @"SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ";
    char query[[q length] + [database length]];
    sprintf(query, "SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ", "quotationary");// (const char *)[database UTF8String]);
    NSLog(@"query %s", query);
    mysql_query(conn, query);
    
    MYSQL_RES *result = mysql_store_result(conn);
    
    if (result) {
        //mutableResult = [[NSMutableSet alloc] initWithCapacity:mysql_num_rows(result)];
        
        //@autoreleasepool {
        MYSQL_ROW row;
        //@autoreleasepool {
        //mysql_fetch_row(result);
        //printf("row %s", row[0]);
            while ((row = mysql_fetch_row(result))) {
                NSLog(@"Got row");
                if (row[0]) {
                    NSString *name = [[NSString alloc] initWithUTF8String:row[0]];
                    if (name) {
                        [mutableResult addObject: name];
                    } else {
                        NSLog(@"Not got name");
                    }
                    NSLog(@"row %s", row[0]);
                    NSLog(@"name %@", name);
                    [name release];

                } else {
                    NSLog(@"Not got row!!!");
                }
            }
        //}
        mysql_free_result(result);
    }
    mysql_close(conn);
     */
    return [resultArray autorelease];
    //return allObjects;
}

- (NSSet *)fieldsFor:(NSString *)database andTable:(NSString *)table {
    /*
    MYSQL *conn = mysql_init(NULL);
    mysql_real_connect(conn, [[self host] UTF8String], [[self username] UTF8String], [[self password] UTF8String], NULL, [self port], NULL, 0);
    
    NSString *query = [[NSString alloc] initWithFormat: @"SELECT column_name, data_type "
                       @"FROM information_schema.columns "
                       @"  WHERE table_name = '%@' "
                       @"      AND table_schema = '%@';", table, database];
    
    
    mysql_query(conn, (char *)[query UTF8String]);
    [query release];
    
    MYSQL_RES *result = mysql_store_result(conn);
    
    NSMutableSet *mutableResult = [[NSMutableSet alloc] initWithCapacity:mysql_num_rows(result)];
    
    @autoreleasepool {
        MYSQL_ROW row;
        
        while ((row = mysql_fetch_row(result))) {
            if (row[0] && row[1]) {
                NSString *name = [[NSString alloc] initWithUTF8String:row[0]];
                NSString *type = [[NSString alloc] initWithUTF8String:row[1]];
                if (name && type) {
                    [mutableResult addObject: [NSDictionary dictionaryWithObject:type forKey:name]];
                }
                [name release];
                [type release];
            }
        }
    }
    
    mysql_free_result(result);
    mysql_close(conn);
    
    return [mutableResult autorelease];
     */
    return [NSSet setWithArray:[NSArray array]];
}

- (BOOL)testConnection {
    __block BOOL result = NO;
    /*
    //@autoreleasepool {
    MYSQL *conn = mysql_init(NULL);
    
    int port = [self port];
    NSString *host = [[self host] retain];
    NSString *user = [[self username] retain];
    NSString *pass = [[self password] retain];
    const char *_h = [host UTF8String];
    const char *_u = [_username UTF8String];
    const char *_p = [_password UTF8String];
    mysql_real_connect(conn, _h, _u, _p, NULL, port, NULL, 0);
    //[_h release];
    //[_u release];
    //[_p release];
    
    [host release];
    [user release];
    [pass release];
    
    const char *clientInfo = mysql_get_client_info();
    const char *hostInfo = mysql_get_host_info(conn);
    const char *serverInfo = mysql_get_server_info(conn);
    const char *err = mysql_error(conn);
    
    if (err) {
        NSLog(@"MySQL Error: %s", err);
    }
    
    if (clientInfo && hostInfo && serverInfo) {
        mysql_query(conn, "SHOW DATABASES;");
        
        MYSQL_RES *queryResult = mysql_store_result(conn);
        
        result = mysql_num_rows(queryResult) > 0;
        
        mysql_free_result(queryResult);
    }
    
    mysql_close(conn);
    //}
    */
    return result;
}

@end