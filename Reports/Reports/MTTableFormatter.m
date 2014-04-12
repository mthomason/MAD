//
//  MTTableFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableFormatter.h"

#import "SectionEnumerator.h"
#import "MTQuery.h"
#import "MTQueryReport.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

#import "RptqQuery+Extras.h"

#import "MTDataTable.h"

@interface MTTableFormatter ()

@property (nonatomic, retain, readwrite) NSArray *sortDescriptorsByGroupSorted;

@end

@implementation MTTableFormatter

- (id)initWithQuery:(MTQuery *)query {
    self = [super initWithQuery:query];
    if (self) {

        [self setQuery:query];
        [self setDidRefresh:NO];
    }
    return self;
}

+ (id)reportFormatterWithQuery:(MTQuery *)query {
    MTTableFormatter *result = [[MTTableFormatter alloc] initWithQuery:query];
    return result;
}

#pragma mark - Reading cached data

- (BOOL)format {
    
    BOOL updatedData = NO;
    
    if ([super format]) {
        
        MTQueryReport *madQuery = [self query];
        NSArray *sortDescriptors = [madQuery sortDescriptors];
        [self setSortDescriptorsByGroupSorted:sortDescriptors];
        
        NSArray *sortedObjects = [[[self query] datatable] sortedRepresentationUsingDescriptors:[self sortDescriptorsByGroupSorted]];
        [self setRecordsSorted:sortedObjects];

        updatedData = YES;
    }

    return updatedData;
}

@end
