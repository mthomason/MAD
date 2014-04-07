//
//  MTDataTableLocation.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTableLocation.h"

@implementation MTDataTableLocation

- (id)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column {
    self = [super init];
    if (self) {
        [self setRow:row];
        [self setColumn:column];
    }
    return self;
}

+ (id)dataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    id result = [[MTDataTableLocation alloc] initWithRow:row inColumn:column];
    return result;
}

@end
