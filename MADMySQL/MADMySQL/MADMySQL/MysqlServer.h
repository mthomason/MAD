//
//  MysqlServer.h
//  mysql_connector
//
//  Created by Karl Kraft on 3/19/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlServer_h
#define MAD_MysqlServer_h

#import <Foundation/NSObject.h>

@interface MysqlServer : NSObject

    @property(copy) NSString *host;
    @property(copy) NSString *user;
    @property(copy) NSString *password;
    @property(copy) NSString *schema;
    @property(assign) unsigned int port;
    @property(assign) unsigned long flags;
    @property(assign) unsigned int connectionTimeout;

@end

#endif
