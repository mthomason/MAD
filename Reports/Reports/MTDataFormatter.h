//
//  MTDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTCachedFileUrl;

@class MTCache, RptqQuery, MTQuery;

@interface MTDataFormatter : NSObject

@property (nonatomic, retain) id query;
@property (nonatomic, retain) MTCache *datasource;
@property (nonatomic, retain) NSArray *records;
@property (nonatomic, assign) BOOL didRefresh;

- (id)initWithQuery:(MTQuery *)query;

- (BOOL)format;
- (NSDictionary *)dataForRow:(NSUInteger)row;

@end
