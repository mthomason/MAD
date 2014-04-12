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

@property (nonatomic, retain, readonly) RptqDocument *layout;
@property (nonatomic, retain, readonly) NSArray *layoutByPage;
@property (nonatomic, retain, readonly) NSArray *dataByPage;
@property (nonatomic, retain, readonly) NSDictionary *dataByGroup;

- (id)initWithQuery:(MTQueryReport *)query andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithQuery:(MTQueryReport *)query andLayout:(RptqDocument *)layout;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage;

- (NSDictionary *)dataForRow:(NSUInteger)row onPage:(NSUInteger)page;

+ (id)dataForGroupData:(id)data andKeys:(NSArray *)keys;
- (NSUInteger)numberOfPages;

@end
