//
//  MTPaperA1.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB1.h"

@implementation MTPaperB1

- (instancetype)init {
    self = [super init];
    if (self) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB1 size]; }
+ (CGSize)size { return [MTPaper sizeB1]; }

- (MTPaperType)paperType { return [MTPaperB1 type]; }
+ (MTPaperType)type { return MTPaperTypeB1; };

@end
