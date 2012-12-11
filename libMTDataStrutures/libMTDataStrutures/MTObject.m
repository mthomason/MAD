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

- (void)dealloc {
    if (_object) [_object release];
    [super dealloc];
}

@end