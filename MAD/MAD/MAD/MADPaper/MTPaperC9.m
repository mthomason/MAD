//
//  MTPaperA9.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperC9.h"

@implementation MTPaperC9

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperC9 size]; }
+ (CGSize)size { return [MTPaper sizeC9]; }

- (MTPaperType)paperType { return [MTPaperC9 type]; }
+ (MTPaperType)type { return MTPaperTypeC9; };

@end
