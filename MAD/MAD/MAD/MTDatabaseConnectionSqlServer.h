//
//  MTDatabaseConnectionSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlServer_h
#define Reports_MTDatabaseConnectionSqlServer_h

#import "MTDatabaseConnection.h"
#import <MADTdsClient/MADTdsClient.h>

@interface MTDatabaseConnectionSqlServer : MTDatabaseConnection

- (instancetype)initWithHost:(NSString *)host
                      server:(NSString *)server
                    database:(NSString *)database
                     andPort:(NSInteger)port;

@end

#endif
