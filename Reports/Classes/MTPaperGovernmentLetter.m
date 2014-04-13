//
//  MTPaperGovernmentLetter.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTPaperGovernmentLetter.h"

@implementation MTPaperGovernemntLetter

- (id)init {
    self = [super init];
    if (self) {
        
        CGFloat width = CGFloatPointsForInches(8.5000f);
        CGFloat height = CGFloatPointsForInches(10.5000f);
        CGSize letter = CGSizeMake(width, height);
        [self setPaperSize:letter];
        
    }
    return self;
}

@end
