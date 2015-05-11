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

#import "MTPaperA6.h"
#import "CGGeometry+Extras.h"

@implementation MTPaperA6

- (instancetype)init {
    self = [super init];
    if (self) {
        
        CGFloat width = CGFloatPointsForMillimeters(105.0000f);
        CGFloat height = CGFloatPointsForMillimeters(148.0000f);
        CGSize size = CGSizeMake(width, height);
        [self setPaperSize:size];
        
    }
    return self;
}

@end
