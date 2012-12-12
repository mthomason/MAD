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

@end