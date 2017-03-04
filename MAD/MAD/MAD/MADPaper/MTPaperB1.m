//
//  MTPaperA1.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB1.h"

@implementation MTPaperB1

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperB1 size]; }
+ (CGSize)size { return [MTPaper sizeB1]; }

- (MTPaperType)paperType { return [MTPaperB1 type]; }
+ (MTPaperType)type { return MTPaperTypeB1; };

@end
