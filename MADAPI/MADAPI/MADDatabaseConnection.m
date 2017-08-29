//
//  MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabaseConnection.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

@implementation MADDatabaseConnection

@dynamic databaseType;
@dynamic requiresCredientals;
@dynamic connectionString;
@dynamic identifier;

- (id)copyWithZone:(nullable NSZone *)zone {
    typeof(self) c = [[self.class alloc] copyWithZone:zone];
    return c;
}

+ (NSString *)Identifier {
    NSAssert(NO, @"This is a factory class.  Don't call this.");
    return nil;
}

@end
