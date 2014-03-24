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

@interface MTDataFormatter ()

@end

@implementation MTDataFormatter

- (id)initWithQuery:(MTQuery *)query {
    self = [super init];
    if (self) {
        [self setQuery:query];
        [self setDatasource:[query cache]];
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
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL cacheAgain = [[[self datasource] url] isEqual:[standardUserDefaults objectForKey:MTCachedFileUrl]] == NO;
    
    if (cacheAgain || [self didRefresh]) {
        updatedData = YES;
        
        [standardUserDefaults setURL:[[self datasource] url] forKey:MTCachedFileUrl];
        [standardUserDefaults synchronize];
        
        NSArray *cachedResultsForReportSerialized = [[self datasource] results];
        
        [self setRecords:cachedResultsForReportSerialized];
        
    }
    return updatedData;
}

- (NSDictionary *)dataForRow:(NSUInteger)row {
    return [[self records] objectAtIndex:row];
}

@end
