//
//  MTDatabaseConnectionMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseConnectionMySql.h"

@implementation MTDatabaseConnectionMySql

- (id)initWithHost:(NSString *)host database:(NSString *)database andPort:(NSInteger)port {
    self = [super init];
    if (self) {
        [self setServer: host];
        [self setDatabase: database];
        [self setPort: port];
        [self setDatabaseTypeIdentifier: [MTDatabaseConnectionMySql identifier]];
    }
    return self;
}

- (NSString *)identifier {
    return [MTDatabaseConnectionMySql identifier];
}

+ (NSString *)identifier {
    return @"MySQL";
}

@end
