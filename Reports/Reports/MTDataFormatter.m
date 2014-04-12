//
//  MTDataFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataFormatter.h"

#import "SectionEnumerator.h"
#import "MTQuery.h"
#import "MTQueryReport.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

#import "RptqQuery+Extras.h"
#import "MTDataTable.h"

@interface MTDataFormatter ()

@end

@implementation MTDataFormatter

- (id)initWithQuery:(MTQuery *)query {
    self = [super init];
    if (self) {
        [self setQuery:query];
        [self setDidRefresh:NO];
    }
    return self;
}


+ (id)reportFormatterWithQuery:(MTQuery *)query {
    MTDataFormatter *result = [[MTDataFormatter alloc] initWithQuery:query];
    return result;
}

#pragma mark - Reading cached data

- (BOOL)format {
    
    BOOL updatedData = NO;
    
    NSAssert([[self query] datatable] != nil, @"We need a datatable way before here");
    
    NSURL *url = [[[self query] datatable] url];
    BOOL cacheExist = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];

    
    if (cacheExist == YES || [self didRefresh]) {
        updatedData = YES;
        
    }
    return updatedData;
}

- (NSDictionary *)dataForRow:(NSUInteger)row {
    NSUInteger index = row;
    return [[[self query] datatable] objectAtIndex:index];
}

@end
