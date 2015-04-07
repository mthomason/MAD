//
//  MTDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTDataFormatter_h
#define MAD_MTDataFormatter_h

#import <Foundation/Foundation.h>

@class RptqQuery, MTQuery, MTDataTable;

@interface MTDataFormatter : NSObject

@property (nonatomic, strong) MTQuery *query;
@property (nonatomic, assign) BOOL didRefresh;
@property (nonatomic, assign, readonly) BOOL needsFormat;

- (instancetype)initWithQuery:(MTQuery *)query;

@end

#endif
