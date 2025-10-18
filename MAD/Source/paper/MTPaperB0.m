//
//  MTPaperA0.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB0.h"

@implementation MTPaperB0

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB0 size]; }
+ (CGSize)size { return [MTPaper sizeB0]; }

- (MTPaperType)paperType { return [MTPaperB0 type]; }
+ (MTPaperType)type { return MTPaperTypeB0; };


@end
