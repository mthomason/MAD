//
//  NSNumber+MTProtocol.m
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//
/*
#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSNumber+MTProtocol.h"

@implementation NSNumber (MTProtocol)

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        result = [self isEqualToNumber:sender];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self stringValue];
}

- (NSString *)toString {
    return [self stringValue];
}

- (NSString *)toStringDebug {
    return [self debugDescription];
}

@end
*/
