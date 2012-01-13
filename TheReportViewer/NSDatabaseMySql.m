//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDatabaseMySql.h"
#import "mysql.h"

@interface NSDatabaseMySql()

@property (retain, nonatomic) NSString *username;
@property (retain, nonatomic) NSString *password;
@property (retain, nonatomic) NSString *host;
@property (assign, nonatomic) NSInteger port;

@end

@implementation NSDatabaseMySql

@synthesize username = _username;
@synthesize password = _password;
@synthesize host = _host;
@synthesize port = _port;

- (void)dealloc {
    [_username release];
    [_password release];
    [_host release];
    [super dealloc];
}

- (id)initWithOptions:(NSDictionary *)optons {
    self = [super initWithOptions:optons];
    if (self) {
        NSString *u = [[optons objectForKey:@"username"] retain];
        [self setUsername: u];
        [u release];
        NSString *p = [[optons objectForKey:@"password"] retain];
        [self setPassword: p];
        [p release];
        NSString *h = [[optons objectForKey:@"host"] retain];
        [self setHost: h];
        [h release];
        [self setPort: [[optons objectForKey:@"port"] integerValue]];
    }
    return self;
}

- (NSSet *)tablesFor:(NSString *)database {
    MYSQL *conn = mysql_init(NULL);
    mysql_real_connect(conn, [[self host] UTF8String], [[self username] UTF8String], [[self password] UTF8String], NULL, [self port], NULL, 0);
    
    NSString *query = [[NSString alloc] initWithFormat: @"SELECT table_name FROM information_schema.tables "
                                                            @"WHERE table_schema = '%@'; ", database];
    mysql_query(conn, (char *)[query UTF8String]);
    [query release];
    
    MYSQL_RES *result = mysql_store_result(conn);
    
    NSMutableSet *mutableResult;
    
    if (result) {
        mutableResult = [[[NSMutableSet alloc] initWithCapacity:mysql_num_rows(result)] autorelease];
        
        @autoreleasepool {
            MYSQL_ROW row;
            
            while ((row = mysql_fetch_row(result))) {
                if (row[0]) {
                    NSString *name = [[NSString alloc] initWithUTF8String:row[0]];
                    if (name) {
                        [mutableResult addObject: name];
                    }
                    [name release];
                }
            }
        }
    } else {
        mutableResult = [[[NSMutableSet alloc] initWithCapacity: 0] autorelease];
    }
    
    mysql_free_result(result);
    mysql_close(conn);
    
    return mutableResult;
}

- (NSSet *)fieldsFor:(NSString *)database andTable:(NSString *)table {
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
}

- (BOOL)testConnection {
    BOOL result = NO;
    
    MYSQL *conn = mysql_init(NULL);
    mysql_real_connect(conn, [[self host] UTF8String], [[self username] UTF8String], [[self password] UTF8String], NULL, [self port], NULL, 0);
    
    const char *clientInfo = mysql_get_client_info();
    const char *hostInfo = mysql_get_host_info(conn);
    const char *serverInfo = mysql_get_server_info(conn);
    
    if (clientInfo && hostInfo && serverInfo) {
        mysql_query(conn, "SHOW DATABASES;");

        MYSQL_RES *queryResult = mysql_store_result(conn);
        
        result = mysql_num_rows(queryResult) > 0;
        
        mysql_free_result(queryResult);
    }
    
    mysql_close(conn);
    
    return result;
}

@end