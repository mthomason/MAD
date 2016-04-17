//
//  MTDatabaseConnectionSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlite3_h
#define Reports_MTDatabaseConnectionSqlite3_h

#import <MAD/MTDatabaseConnection.h>

@interface MTDatabaseConnectionSqlite3 : MTDatabaseConnection

    - (instancetype)initWithUrl:(NSURL *)url;
    @property (nonatomic, readonly, copy) NSURL *databaseUrl;

@end

#endif
