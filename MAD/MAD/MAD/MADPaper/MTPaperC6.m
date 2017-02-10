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

#import "MTPaperC6.h"

@implementation MTPaperC6

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperC6 size]; }
+ (CGSize)size { return [MTPaper sizeC6]; }

- (MTPaperType)paperType { return [MTPaperC6 type]; }
+ (MTPaperType)type { return MTPaperTypeC6; };

@end
