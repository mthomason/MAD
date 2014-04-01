//
//  MTDatabaseProcessSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sybdb.h"

@interface MTDatabaseProcessSqlServer : NSObject

- (id)initWithProcess:(DBPROCESS *)process;
- (DBPROCESS *)process;

@end
