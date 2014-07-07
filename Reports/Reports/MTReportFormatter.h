//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTTableFormatter.h"

typedef NS_OPTIONS(NSInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone   = 1 << 0,
};

extern NSString * const MTNullIdentifier;

@class RptqDocumentSection, RptqDocument;

@interface MTReportFormatter : MTTableFormatter

- (id)initWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options contentChanged:(BOOL)contextChanged;

- (id)dataForGroupKeys:(NSArray *)keys;
- (NSUInteger)numberOfPages;

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;

- (NSArray *)layoutForPage:(NSUInteger)page;
- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId;
- (NSEnumerator *)dataForPageIndex:(NSInteger)pageIndex;
- (NSDictionary *)resultsForPageIndex:(NSInteger)pageIndex;

- (NSDictionary *)firstObjectOnReport;
- (NSDictionary *)lastObjectOnReport;
- (NSDictionary *)firstObjectOnPageAtIndex:(NSInteger)pageIndex;
- (NSDictionary *)lastObjectOnPageAtIndex:(NSInteger)pageIndex;

+ (NSValue *)KeyReportSectionType;
- (NSIndexSet *)rowidsForPage:(NSInteger)pageIndex;

- (NSArray *)keysForGroup:(NSUInteger)group;

- (NSUInteger)numberOfGroups;

@property (nonatomic, strong, readwrite) NSArray *sortedQueryGroups;

@end
