//
//  MTPaperA10.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB10.h"

@implementation MTPaperB10

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB10 size]; }
+ (CGSize)size { return [MTPaper sizeB10]; }

- (MTPaperType)paperType { return [MTPaperB10 type]; }
+ (MTPaperType)type { return MTPaperTypeB10; };

@end
