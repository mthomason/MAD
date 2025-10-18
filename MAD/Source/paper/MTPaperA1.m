//
//  MTPaperA1.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA1.h"

@implementation MTPaperA1

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA1 size]; }
+ (CGSize)size { return [MTPaper sizeA1]; }

- (MTPaperType)paperType { return [MTPaperA1 type]; }
+ (MTPaperType)type { return MTPaperTypeA1; };


@end
