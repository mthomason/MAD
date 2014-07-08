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

@class RptqDocumentSection, RptqDocument, MTArrayCached;

@protocol MTReportFormatterDataSource <NSObject>

- (NSEnumerator *)enumeratorForReportData;

@end

@interface MTReportFormatter : MTTableFormatter

- (id)initWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options contentChanged:(BOOL)contextChanged;

- (NSUInteger)numberOfPages;
- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
- (NSArray *)layoutForPage:(NSUInteger)page;

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;
+ (NSValue *)KeyReportSectionType;
- (NSIndexSet *)rowidsForPage:(NSInteger)pageIndex;
- (NSArray *)keysForGroup:(NSUInteger)group;
- (NSUInteger)numberOfGroups;

@property (nonatomic, assign) id <MTReportFormatterDataSource> datasource;

@property (nonatomic, strong, readwrite) NSArray *sortedQueryGroups;
@property (nonatomic, strong, readonly) RptqDocument *layout;

@property (nonatomic, strong, readonly) MTArrayCached *reportIndexes;
@property (nonatomic, strong, readonly) MTArrayCached *reportLayout;
@property (nonatomic, strong, readonly) MTArrayCached *groupKeys;

@end
