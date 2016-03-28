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

@interface MTDatabaseConnectionSqlite3 ()

    @property (nonatomic, readwrite, copy) NSURL *databaseUrl;

@end

@implementation MTDatabaseConnectionSqlite3

- (instancetype)initWithUrl:(NSURL *)url {
    if (self = [super init]) {
        _databaseUrl = url.copy;
        self.databaseTypeIdentifier = MADIdentifierDatabaseSqlite3;
    }
    return self;
}

- (NSString *)connectionString {
    NSString * __autoreleasing connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@]", self.databaseTypeIdentifier, self.databaseUrl];
    return connectionString;
}

- (NSString *)identifier {
    return MADIdentifierDatabaseSqlite3;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseSqlite3;
}

- (NSURL *)databaseUrl {
    NSURL * __autoreleasing url = _databaseUrl.copy;
    return url;
}

@end
