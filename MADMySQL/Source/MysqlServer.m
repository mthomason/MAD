//
//  MysqlServer.m
//  mysql_connector
//
//  Created by Karl Kraft on 3/19/11.
//  Copyright 2011-2012 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlServer.h"
#import <mysql.h>
#import <Foundation/NSString.h>

@implementation MysqlServer

- (instancetype)init {
	if (self = [super init]) {
		self.host = @"localhost";
		self.user = @"username";
		self.password = @"password";
		self.schema = @"test";
		self.port = 3306;
		self.flags = CLIENT_FOUND_ROWS;
		self.connectionTimeout = 30;
	}
	return self;
}

- (NSString *)description {
	NSString *description;
	description = [[NSString alloc] initWithFormat: @"MysqlServer: %@:%d as user %@",
													_host, _port, _user];
	return description;
}

@end
