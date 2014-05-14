//
//  MTDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//



#import <Foundation/Foundation.h>

@class RptqQuery, MTQuery, MTDataTable;

@interface MTDataFormatter : NSObject

@property (nonatomic, strong) MTQuery *query;
@property (nonatomic, assign) BOOL didRefresh;

 - (id)initWithQuery:(MTQuery *)query;

- (BOOL)format;
- (NSDictionary *)dataForRow:(NSUInteger)row;
- (NSUInteger)numberOfResults;

@end
