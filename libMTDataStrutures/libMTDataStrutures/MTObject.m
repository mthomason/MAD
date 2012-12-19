//
//  MTObject.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTObject.h"

@interface MTObject ()

@end

@implementation MTObject

- (id)init {
    return [self initWithObject:nil];
}

- (id)initWithObject:(id)object {
    self = [super init];
    if (self) {
        id obj = [object retain];
        [self setObject:obj];
        [obj release];
    }
    return self;
}

+ (id)objectWithObject:(id)object {
    MTObject *result = [[MTObject alloc] initWithObject:object];
    return [result autorelease];
}

- (void)dealloc {
    [_object release];
    [super dealloc];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([[self object] conformsToProtocol:@protocol(MTProtocolCompare)]) {
        result = [[self object] isEqualTo:sender];
    } else {
        result = [[self object] isEqual:sender];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [[self object] toStringHumanReadable];
}

- (NSString *)toString {
    return [[self object] toString];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", [self object]];
}

@end