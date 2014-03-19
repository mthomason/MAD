//
//  MTDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseSqlite3.h"

@implementation MTDatabaseConnectionSqlite3

- (id)initWithUrl:(NSURL *)url {
    
    self = [super init];
    if (self) {
        [self setDatabaseUrl: url];
        [self setDatabaseTypeIdentifier: [MTDatabaseSqlite3 identifier]];

    }
    return self;
    
}

@end
