//
//  MTTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTDataFormatter.h"

@class MTCache, MTQueryReport;

@interface MTTableFormatter : MTDataFormatter

@property (nonatomic, retain, readonly) NSArray *sortDescriptorsByGroupSorted;
@property (nonatomic, assign) BOOL didRefresh;

@property (nonatomic, retain) NSArray *recordsSorted;

// FIXME: Make initWithQuery andLayout... passlayout to 

- (id)initWithQuery:(MTQuery *)query;
+ (id)reportFormatterWithQuery:(MTQuery *)query;

@end
