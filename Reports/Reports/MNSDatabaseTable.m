//
//  MNSDatabaseTable.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabaseTable.h"

@implementation MNSDatabaseTable

- (void)dealloc {
    [_name release];
    [_label release];
    [_labelPlural release];
    [super dealloc];
}

@end