//
//  MTDatabaseProcessSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseProcessSqlServer_h
#define Reports_MTDatabaseProcessSqlServer_h

#import <Foundation/NSObject.h>

@interface MTDatabaseProcessSqlServer : NSObject

    - (instancetype)initWithProcess:(void /* DBPROCESS */ *)process;
    - (void /* DBPROCESS */ *)process NS_RETURNS_INNER_POINTER;

@end

#endif
