//
//  MADDatabaseProcessSQLServer.m
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseProcessSQLServer.h"
#import <MADTds/sybdb.h>
#import <MADTds/MADTdsDb.h>

@implementation MADDatabaseProcessSQLServer {
	DBPROCESS *_dbconn;
}

- (instancetype)initWithProcess:(void *)process {
	if (self = [self init]) {
		_dbconn = (DBPROCESS *)process;
	}
	return self;
}

- (void *)process { return _dbconn; }

@end
