//
//  MTPaperA6.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB6.h"
#import "CGGeometry+Extras.h"

@implementation MTPaperB6

- (instancetype)init {
    self = [super init];
    if (self) {
        
        CGFloat width = CGFloatPointsForMillimeters(125.0000f);
        CGFloat height = CGFloatPointsForMillimeters(176.0000f);
        CGSize size = CGSizeMake(width, height);
        [self setPaperSize:size];
        
    }
    return self;
}

@end
