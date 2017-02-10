//
//  MTPaperA8.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA8.h"

@implementation MTPaperA8

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA8 size]; }
+ (CGSize)size { return [MTPaper sizeA8]; }

- (MTPaperType)paperType { return [MTPaperA8 type]; }
+ (MTPaperType)type { return MTPaperTypeA8; };

@end
