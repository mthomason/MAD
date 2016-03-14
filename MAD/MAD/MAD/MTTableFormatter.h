//
//  MTTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTTableFormatter_h
#define MAD_MTTableFormatter_h

#import <MAD/MTDataFormatter.h>

@class MTQuery;

@interface MTTableFormatter : MTDataFormatter

@property (nonatomic, assign) BOOL didRefresh;

- (instancetype)initWithQuery:(MTQuery *)query;

@end

#endif
