//
//  NSString+MTProtocol.m
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSString+MTProtocol.h"

@implementation NSString (MTProtocol)

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        result = [self isEqualToString:sender];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return self;
}

- (NSString *)toString {
    return self;
}

- (NSString *)toStringDebug {
    return self;
}

@end