//
//  MTObject.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTObject.h"
#import <Foundation/NSString.h>

@interface MTObject ()

@end

@implementation MTObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.object = nil;
    }
    return self;
}

- (instancetype)initWithObject:(id <NSCopying>)object {
    if (self = [super init]) {
        _object = [object copyWithZone:nil];
    }
    return self;
}

+ (instancetype)objectWithObject:(id <NSCopying>)object {
    return [[self alloc] initWithObject:object];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self.object conformsToProtocol:@protocol(MTProtocolCompare)]) {
        result = [self.object isEqualTo:sender];
    } else {
        result = [self.object isEqual:sender];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self.object toStringHumanReadable];
}

- (NSString *)toString {
    return [self.object toString];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self.object];
}

@end
