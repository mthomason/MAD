//
//  MTDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnectionSqlite3.h"

@implementation MTDatabaseConnectionSqlite3

- (instancetype)initWithUrl:(NSURL *)url {
    
    self = [super init];
    if (self) {

        NSURL *databaseUrl = [url copy];
        self.databaseUrl = databaseUrl;
        self.databaseTypeIdentifier = [self identifier];

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
