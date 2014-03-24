//
//  MTTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTCache, RptqQuery, MTQueryReport;

@interface MTTableFormatter : NSObject

@property (nonatomic, retain, readonly) MTCache *datasource;
@property (nonatomic, retain, readonly) RptqQuery *fullQuery;
@property (nonatomic, retain, readonly) NSArray *sortedQueryGroups;
@property (nonatomic, retain, readonly) NSArray *sortDescriptorsByGroupSorted;
@property (nonatomic, retain, readonly) NSArray *records;
@property (nonatomic, assign) BOOL didRefresh;

- (id)initWithQuery:(MTQueryReport *)query;
+ (id)reportFormatterWithQuery:(MTQueryReport *)query;

- (BOOL)format;

@end
