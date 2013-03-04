//
//  MNSDatabaseTable.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseTable.h"

@implementation MTDatabaseTable

- (void)dealloc {
    [_name release];
    [_label release];
    [_labelPlural release];
    [super dealloc];
}

- (id)initWithTableName:(NSString *)tableName {
    self = [super init];
    if (self) {
        [self setName: tableName];
        [self setLabel: tableName];
        [self setLabelPlural: tableName];   // TODO: Add porter steamer.
    }
    return self;
}

@end
