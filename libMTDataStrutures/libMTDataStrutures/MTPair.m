//
//  MTPair.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTPair.h"

@interface MTPair ()

@end

@implementation MTPair

- (void)dealloc {
    if (_former) [_former release];
    if (_latter) [_latter release];
    [super dealloc];
}

- (id)init {
    return [self initWithFormer:nil andLater:nil];
}

- (id)initWithFormer:(id)former andLater:(id)later {
    self = [super init];
    if (self) {
        [self setFormer:former];
        [self setLatter:later];
    }
    return self;
}

@end