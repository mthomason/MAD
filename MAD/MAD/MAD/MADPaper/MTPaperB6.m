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

@implementation MTPaperB6

- (instancetype)init {
    self = [super init];
    if (self) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB6 size]; }
+ (CGSize)size { return [MTPaper sizeB6]; }

- (MTPaperType)paperType { return [MTPaperB6 type]; }
+ (MTPaperType)type { return MTPaperTypeB6; };

@end
