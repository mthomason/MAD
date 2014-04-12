//
//  MTDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnectionSqlite3.h"

@implementation MTDatabaseConnectionSqlite3

- (id)initWithUrl:(NSURL *)url {
    
    self = [super init];
    if (self) {
        NSURL *databaseUrl = [url copy];
        [self setDatabaseUrl: databaseUrl];
        [databaseUrl release];
        
        [self setDatabaseTypeIdentifier: [MTDatabaseConnectionSqlite3 identifier]];

    }
    return self;
    
}

- (NSString *)identifier {
    return [MTDatabaseConnectionSqlite3 identifier];
}

+ (NSString *)identifier {
    return @"Sqlite 3";
}

@end
