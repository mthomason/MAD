//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabaseMySql.h"
#import <stdio.h>
#import "Constants.h"

@interface NSDatabaseMySql()

@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *host;
@property (assign) NSInteger port;

@end

@implementation NSDatabaseMySql

- (void)dealloc {
    [_username release];
    [_password release];
    [_host release];
    [super dealloc];
}

- (id)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username andPassword:(NSString *)password {
    self = [super init];
    if (self) {
        [self setUsername: username];
        [self setPassword: password];
        [self setHost: host];
        [self setPort: port];
    }
    return self;
}

- (id)initWithOptions:(NSDictionary *)optons {
    self = [super init];
    if (self) {

    }
    return self;
}

@end