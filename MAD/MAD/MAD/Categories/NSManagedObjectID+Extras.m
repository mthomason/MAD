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
    char buf[18];
    ultoa(self.hash, buf);
    snprintf(buf, 18, "s%lu", (unsigned long)self.hash);
    id result = [[NSString alloc] initWithUTF8String:buf];
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
