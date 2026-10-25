//
//  MADMySQLServer.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLServer_h
#define MAD_MADMySQLServer_h

#import <Foundation/NSObject.h>

/*
	The connection parameters for one MySQL server: host, credentials, the
	schema to select, and the client flags and timeout the connection is made
	with. The default instance describes a stock local server.
 */
@interface MADMySQLServer : NSObject

	@property(nonatomic, copy) NSString *host;
	@property(nonatomic, copy) NSString *user;
	@property(nonatomic, copy) NSString *password;
	@property(nonatomic, copy) NSString *schema;
	@property(nonatomic, assign) unsigned int port;
	@property(nonatomic, assign) unsigned long flags;
	@property(nonatomic, assign) unsigned int connectionTimeout;

@end

#endif
