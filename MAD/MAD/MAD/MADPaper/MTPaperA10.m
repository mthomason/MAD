//
//  MTPaperA10.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA10.h"

@implementation MTPaperA10

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA10 size]; }
+ (CGSize)size { return [MTPaper sizeA10]; }

- (MTPaperType)paperType { return [MTPaperA10 type]; }
+ (MTPaperType)type { return MTPaperTypeA10; };

@end
