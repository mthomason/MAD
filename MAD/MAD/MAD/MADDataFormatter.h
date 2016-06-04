//
//  MADDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDataFormatter_h
#define MAD_MADDataFormatter_h

#import <Foundation/NSObject.h>

@class RptqQuery;
@class MTQuery;
@class MTDataTable;

@interface MADDataFormatter : NSObject

    @property (nonatomic, strong) MTQuery *query;
    @property (nonatomic, assign) BOOL didRefresh;
    @property (nonatomic, assign, readonly) BOOL needsFormat;

    - (instancetype)initWithQuery:(MTQuery *)query;

@end

#endif
