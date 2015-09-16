//
//  MTDatabaseProcessSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseProcessSqlServer_h
#define Reports_MTDatabaseProcessSqlServer_h

#import <Foundation/Foundation.h>
#import <MADTdsClient/MADTdsClient.h>

@interface MTDatabaseProcessSqlServer : NSObject

- (instancetype)initWithProcess:(DBPROCESS *)process;
- (DBPROCESS *)process;

@end

#endif
