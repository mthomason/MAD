//
//  MTPaperA2.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperC2.h"

@implementation MTPaperC2

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperC2 size]; }
+ (CGSize)size { return [MTPaper sizeC2]; }

- (MTPaperType)paperType { return [MTPaperC2 type]; }
+ (MTPaperType)type { return MTPaperTypeC2; };

@end
