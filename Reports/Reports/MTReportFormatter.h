//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTTableFormatter.h"

extern NSString * const MTNullIdentifier;

@class RptqDocument;

@interface MTReportFormatter : MTTableFormatter

//@property (nonatomic, retain, readonly) RptqDocument *layout;

- (id)initWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage;

- (NSDictionary *)dataForRow:(NSUInteger)row onPage:(NSUInteger)page;

- (id)dataForGroupKeys:(NSArray *)keys;
- (NSUInteger)numberOfPages;
- (NSUInteger)countOnPageIndex:(NSUInteger)pageIndex;

- (NSEnumerator *)objectEnumeratorForPage:(NSUInteger)pageIndex;
- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;

@end
