//
//  MTDatabaseProcessSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sybdb.h"
#import "Constants.h"

@interface MTDatabaseProcessSqlServer : NSObject

- (instancetype)initWithProcess:(DBPROCESS *)process NS_DESIGNATED_INITIALIZER;
- (DBPROCESS *)process;

@end
