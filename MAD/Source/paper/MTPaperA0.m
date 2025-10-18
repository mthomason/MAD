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

#import "MTPaperA0.h"

@implementation MTPaperA0

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA0 size]; }
+ (CGSize)size { return [MTPaper sizeA0]; }

- (MTPaperType)paperType { return [MTPaperA0 type]; }
+ (MTPaperType)type { return MTPaperTypeA0; };

@end
