//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTNullIdentifier;

@class MTCache, RptqDocument;

@interface MTReportFormatter : NSObject

@property (nonatomic, retain, readonly) NSArray *cachedLayoutByPage;
@property (nonatomic, retain, readonly) NSArray *cachedDataByPage;
@property (nonatomic, retain, readonly) NSArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, retain, readonly) NSArray *cachedDataByReport;
@property (nonatomic, retain, readonly) NSDictionary *cachedDataByGroup;

- (id)initWithDatasource:(MTCache *)datasource andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithDatasource:(MTCache *)datasource andLayout:(RptqDocument *)layout;

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize;
- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage;

- (NSDictionary *)rowDataForRow:(NSUInteger)row onPage:(NSUInteger)page;

- (id)dataForCachedGroupData:(id)data andKeys:(NSArray *)keys;
- (NSUInteger)numberOfPages;

@end
