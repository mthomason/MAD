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

@implementation MTPaperGovernemntLegal

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperGovernemntLegal size]; }
+ (CGSize)size { return [MTPaper sizeGovernmentLegal]; }

- (MTPaperType)paperType { return [MTPaperGovernemntLegal type]; }
+ (MTPaperType)type { return MTPaperTypeGovernmentLegal; };

@end

