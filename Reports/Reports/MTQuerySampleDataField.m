//
//  MTQuerySampleDataField.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuerySampleDataField.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "MTDatabase.h"
#import "Constants.h"

@interface MTQuerySampleDataField ()

@end

@implementation MTQuerySampleDataField

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        Class classRptqQuery = [RptqDatabaseSchemaField class];
        if ([object isKindOfClass:classRptqQuery]) {
            [self setQueryObject:object];
        }
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    NSString *key = [[self database] fieldAliasForField:[self queryObject]];
    [[self fieldKeys] addObject:key];
    return [[self database] sqlSampleDataForField:[self queryObject]];
}

@end
