//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseField.h"

@implementation MTDatabaseField

- (void)dealloc {
    [_label release];
    [_name release];
    [_datatype release];
    [super dealloc];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        [self setLabel: name];
        [self setName: name];
        [self setDatatype: name];
    }
    return self;
}

@end