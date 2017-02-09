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

    @property(nonatomic, copy) NSString *host;
    @property(nonatomic, copy) NSString *user;
    @property(nonatomic, copy) NSString *password;
    @property(nonatomic, copy) NSString *schema;
    @property(nonatomic, assign) unsigned int port;
    @property(nonatomic, assign) unsigned long flags;
    @property(nonatomic, assign) unsigned int connectionTimeout;

@end

#endif
