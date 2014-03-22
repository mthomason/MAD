//
//  MTTableFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableFormatter.h"
#import "MTCache.h"

#import "SectionEnumerator.h"
#import "MTQuery.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

#import "RptqQuery+Extras.h"

@interface MTTableFormatter ()

@property (nonatomic, assign, readwrite) BOOL didRefresh;

@property (nonatomic, retain, readwrite) MTCache *datasource;
@property (nonatomic, retain, readwrite) RptqDocument *layout;
@property (nonatomic, retain, readwrite) NSArray *sortedQueryGroups;
@property (nonatomic, retain, readwrite) NSArray *sortDescriptorsByGroupSorted;
@property (nonatomic, retain, readwrite) NSArray *records;

@end

@implementation MTTableFormatter

- (void)dealloc {
    [_datasource release];
    [_layout release];
    [_sortDescriptorsByGroupSorted release];
    [_records release];
    [_sortedQueryGroups release]; _sortedQueryGroups = nil;
    [super dealloc];
}

- (id)initWithDatasource:(MTCache *)datasource andLayout:(RptqDocument *)layout {
    self = [super init];
    if (self) {
        [self setDatasource:datasource];
        [self setLayout:layout];
        [self setDidRefresh:NO];
    }
    return self;
}

+ (id)reportFormatterWithDatasource:(MTCache *)datasource andLayout:(RptqDocument *)layout {
    MTTableFormatter *result = [[MTTableFormatter alloc] initWithDatasource:datasource andLayout:layout];
    return [result autorelease];
}

#pragma mark - Reading cached data

- (BOOL)format {
    
    BOOL updatedData = NO;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL cacheAgain = [[[self datasource] url] isEqual:[standardUserDefaults objectForKey:@"MTCachedFileUrl"]] == NO;
    
    if (cacheAgain || [self didRefresh]) {
        updatedData = YES;

        [standardUserDefaults setURL:[[self datasource] url] forKey:@"MTCachedFileUrl"];
        [standardUserDefaults synchronize];
        
        [self setDidRefresh:NO];
        
        RptqDatabase *database = [[[self layout] hasDatabaseSchemas] anyObject];
        
        NSSet *hasQueries = [database hasQueries];
        RptqQuery *query = [hasQueries anyObject];
        
        MTQuery *madQuery = [[MTQuery queryFactory:query] retain];
        
        NSMutableDictionary *cachedResultsForReport = [[NSMutableDictionary alloc] init];
                
        NSURL *url = [[[self datasource] url] retain];
        NSArray *cachedResultsForReportSerialized = [[self datasource] results];
        
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        NSString *sortKey = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey ascending: YES];
        NSArray *sortedHasQueryGroups = [[hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]] retain];
        [self setSortedQueryGroups:sortedHasQueryGroups];
        [sortedHasQueryGroups release];
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            RptqQueryField *groupField = [queryGroup hasField];
            
            NSString *queryTable = [[groupField inQueryTable] queryAlias];
            NSString *safeQueryTable = [madQuery safeIdentifier:queryTable];
            NSString *fieldName = [[groupField databaseSchemaField] name];
            NSString *safeFieldName = [madQuery safeIdentifier:fieldName];
            NSString *key = [NSString stringWithFormat:@"%@.%@", safeQueryTable, safeFieldName];
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: sortAscending];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
            [sortDescriptor release];
        }
        
        [self setSortDescriptorsByGroupSorted:sortedSortDescriptorsGroup];
        
        //Get unique, distinct, and sorted... slowly
        
        NSArray *sortedArray = [[cachedResultsForReportSerialized sortedArrayUsingDescriptors:[self sortDescriptorsByGroupSorted]] retain];
        
        [self setRecords:sortedArray];

        [madQuery release];
        [sortedArray release];
        [sortedSortDescriptorsGroup release];
        [url autorelease];
        [cachedResultsForReport release];
        [sortDescriptor release];
        
    }
    return updatedData;
}

@end
