//
//  MTDatabaseProcessSqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseProcessSqlServer.h"

@implementation MTDatabaseProcessSqlServer {
    DBPROCESS *dbconn;
}

- (id)initWithProcess:(DBPROCESS *)process {
    self = [super init];
    if (self) {
        dbconn = process;
    }
    return self;
}

- (DBPROCESS *)process {
    return dbconn;
}

@end
