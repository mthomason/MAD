//
//  MADTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableFormatter_h
#define MAD_MADTableFormatter_h

#import <MAD/MADDataFormatter.h>

@class MTQuery;

@interface MADTableFormatter : MADDataFormatter

    @property (nonatomic, assign) BOOL didRefresh;

    - (instancetype)initWithQuery:(MTQuery *)query;

@end

#endif
