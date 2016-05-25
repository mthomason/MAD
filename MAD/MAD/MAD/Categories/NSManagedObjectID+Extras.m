//
//  NSManagedObjectID+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObjectID+Extras.h"
#import <Foundation/NSString.h>
#import <madlib.h>

@implementation NSManagedObjectID (Extras)

@dynamic copyKey;

#pragma mark - MTProtocolLog

- (NSString *)copyKey {
    char buf[12];
    buf[0] = 's';
    uitoa(self.hash, (buf+1));
    char *ptr = buf;
    id result = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return result;
}

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@", self];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%@", self];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end
