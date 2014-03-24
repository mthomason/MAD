//
//  MTTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTDataFormatter.h"

@class MTCache, RptqQuery, MTQueryReport;

@interface MTTableFormatter : MTDataFormatter

@property (nonatomic, retain, readonly) NSArray *sortDescriptorsByGroupSorted;
@property (nonatomic, assign) BOOL didRefresh;

// FIXME: Make initWithQuery andLayout... passlayout to 

- (id)initWithQuery:(MTQueryReport *)query;
+ (id)reportFormatterWithQuery:(MTQueryReport *)query;

@end
