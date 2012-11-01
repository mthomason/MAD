//
//  NSDatabaseMySql.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabase.h"

//FIXME: MySQL Currently does not work.  Takes too much time/too little value to fix.  Maybe find
//          third party distribution.

@interface NSDatabaseMySql : NSDatabase {
    const char *h;
    const char *u;
    const char *p;
}

@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *host;
@property (assign) NSInteger port;

- (id)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username andPassword:(NSString *)password;
- (id)initWithOptions:(NSDictionary *)optons;

- (NSArray *)tablesFor:(NSString *)database;
- (NSSet *)fieldsFor:(NSString *)database andTable:(NSString *)table;
- (BOOL)testConnection;

@end