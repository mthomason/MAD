//
//  MNSDatabaseConnection.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseConnection.h"

// FIXME: No constant provided by iOS.
NSString *const MTBundleDisplayName = @"CFBundleDisplayName";

@implementation MTDatabaseConnection

- (void)dealloc {
    [_username release];
    [_password release];
    [_server release];
    [_database release];
    [_server release];
    [super dealloc];
}

- (NSString *)appname {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];;
}

@end