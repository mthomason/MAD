//
//  NSManagedObjectID+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObjectID+Extras.h"

@implementation NSManagedObjectID (Extras)

#pragma mark - MTProtocolLog

- (NSString *)key {
    char buf[18];
    snprintf(buf, 18, "s%lu", (unsigned long)self.hash);
    return [NSString stringWithUTF8String:buf];
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
