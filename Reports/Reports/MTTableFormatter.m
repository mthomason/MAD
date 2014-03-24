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
#import "MTCache.h"

#import "SectionEnumerator.h"
#import "MTQuery.h"
#import "MTQueryReport.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

#import "RptqQuery+Extras.h"

NSString * const MTCachedFileUrl = @"MTCachedFileUrl";

@interface MTTableFormatter ()

@property (nonatomic, retain, readwrite) MTQueryReport *query;

@property (nonatomic, retain, readwrite) MTCache *datasource;
@property (nonatomic, retain, readwrite) RptqQuery *fullQuery;
@property (nonatomic, retain, readwrite) NSArray *sortDescriptorsByGroupSorted;
@property (nonatomic, retain, readwrite) NSArray *records;

@end

@implementation MTTableFormatter

- (id)initWithQuery:(MTQueryReport *)query {
    self = [super init];
    if (self) {

        [self setQuery:query];
        [self setDatasource:[query cache]];
        [self setFullQuery:[query queryObject]];
        [self setDidRefresh:NO];
    }
    return self;
}

+ (id)reportFormatterWithQuery:(MTQueryReport *)query {
    MTTableFormatter *result = [[MTTableFormatter alloc] initWithQuery:query];
    return result;
}

#pragma mark - Reading cached data

- (BOOL)format {
    
    BOOL updatedData = NO;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL cacheAgain = [[[self datasource] url] isEqual:[standardUserDefaults objectForKey:MTCachedFileUrl]] == NO;
    
    if (cacheAgain || [self didRefresh]) {
        updatedData = YES;

        [standardUserDefaults setURL:[[self datasource] url] forKey:MTCachedFileUrl];
        [standardUserDefaults synchronize];

        MTQueryReport *madQuery = [self query];
        
        NSArray *cachedResultsForReportSerialized = [[self datasource] results];
        
        NSArray *sortDescriptors = [madQuery sortDescriptors];
        [self setSortDescriptorsByGroupSorted:sortDescriptors];
        
        //Get unique, distinct, and sorted... slowly
        
        NSArray *sortedArray = [cachedResultsForReportSerialized sortedArrayUsingDescriptors:[self sortDescriptorsByGroupSorted]];
        
        [self setRecords:sortedArray];

    }
    return updatedData;
}

@end
