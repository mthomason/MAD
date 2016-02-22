//
//  MTPaperA9.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB9.h"

@implementation MTPaperB9

- (instancetype)init {
    self = [super init];
    if (self) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB9 size]; }
+ (CGSize)size { return [MTPaper sizeB9]; }

- (MTPaperType)paperType { return [MTPaperB9 type]; }
+ (MTPaperType)type { return MTPaperTypeB9; };

@end
