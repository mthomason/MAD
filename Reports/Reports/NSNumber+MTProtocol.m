//
//  NSNumber+MTProtocol.m
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSNumber+MTProtocol.h"

@implementation NSNumber (MTProtocol)

#pragma mark - MTProtocolLog

- (NSString *)humanReadableObjectIdentifier {
    return [self stringValue];
}

- (NSString *)toString {
    return [self stringValue];
}

- (NSString *)toStringForDebugging {
    return [self debugDescription];
}

@end