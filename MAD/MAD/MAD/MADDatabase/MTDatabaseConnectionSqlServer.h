//
//  MTDatabaseConnectionSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlServer_h
#define Reports_MTDatabaseConnectionSqlServer_h

#import <MAD/MTDatabaseConnection.h>

@interface MTDatabaseConnectionSqlServer : MTDatabaseConnection
    <NSCopying>
    
    - (instancetype)initWithHost:(NSString *)host
                          server:(NSString *)server
                        database:(NSString *)database
                         andPort:(NSInteger)port;

    @property (nonatomic, readonly, copy) NSString  *database;
    @property (nonatomic, readonly, copy) NSString  *server;
    @property (nonatomic, readonly, copy) NSString  *host;
    @property (nonatomic, readonly, assign) NSInteger port;

@end

#endif
