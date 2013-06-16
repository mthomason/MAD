//
//  libTdsClient.h
//  libTdsClient
//
//  Created by Michael Thomason on 6/6/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/param.h>
#include "sybfront.h"
#include "sybdb.h"

@interface MTTdsClient : NSObject

extern NSString * const MTDatabaseUsernameKey;
extern NSString * const MTDatabasePasswordKey;
extern NSString * const MTDatabaseDatabaseKey;
extern NSString * const MTDatabasePortKey;
extern NSString * const MTDatabaseHostKey;
extern NSString * const MTDatabaseKeyAppName;

- (id)initWithCredentals:(NSDictionary *)credentals;
- (id)runQuery:(NSString *)sql;

@end
