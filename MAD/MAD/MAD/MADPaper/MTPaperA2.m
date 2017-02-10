//
//  MTPaperA2.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA2.h"

@implementation MTPaperA2

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA2 size]; }
+ (CGSize)size { return [MTPaper sizeA2]; }

- (MTPaperType)paperType { return [MTPaperA2 type]; }
+ (MTPaperType)type { return MTPaperTypeA2; };

@end

