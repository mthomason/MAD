//
//  MTTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTDataFormatter.h"

@interface MTTableFormatter : MTDataFormatter

@property (nonatomic, assign) BOOL didRefresh;

- (id)initWithQuery:(MTQuery *)query;
+ (id)reportFormatterWithQuery:(MTQuery *)query;

@end
