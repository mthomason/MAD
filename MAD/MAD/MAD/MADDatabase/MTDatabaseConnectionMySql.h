//
//  MTDatabaseConnectionMySql.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionMySql_h
#define Reports_MTDatabaseConnectionMySql_h

#import "MTDatabaseConnection.h"

@interface MTDatabaseConnectionMySql : MTDatabaseConnection

    - (instancetype)initWithHost:(NSString *)host
                        database:(NSString *)database
                         andPort:(NSInteger)port;

    @property (nonatomic, readonly, copy)      NSString  *server;
    @property (nonatomic, readonly, copy)      NSString  *database;
    @property (nonatomic, readonly, assign)    NSInteger port;

@end

#endif
