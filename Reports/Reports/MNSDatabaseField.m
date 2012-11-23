//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabaseField.h"

@implementation MNSDatabaseField

- (void)dealloc {
    [_label release];
    [_name release];
    [_datatype release];
    [super dealloc];
}

@end