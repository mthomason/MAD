//
//  MADDatabaseProcessSQLServer.m
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
