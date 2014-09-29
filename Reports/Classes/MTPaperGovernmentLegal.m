//
//  MTPaperGovernmentLegal.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperGovernmentLegal.h"
#import "CGGeometry+Extras.h"

@implementation MTPaperGovernemntLegal

- (instancetype)init {
    self = [super init];
    if (self) {
        CGFloat width = CGFloatPointsForInches(8.5000f);
        CGFloat height = CGFloatPointsForInches(14.0000f);
        CGSize letter = CGSizeMake(width, height);
        [self setPaperSize:letter];
    }
    return self;
}

@end

