//
//  MTDatabaseProcessSqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseProcessSqlServer.h"
#import <MADTdsClient/sybdb.h>

@implementation MTDatabaseProcessSqlServer {
    DBPROCESS *dbconn;
}

- (instancetype)initWithProcess:(void *)process {
    if (self = [self init]) {
        dbconn = (DBPROCESS *)process;
    }
    return self;
}

- (void *)process { return dbconn; }

@end
