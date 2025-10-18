//
//  MTPaperA10.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperC10.h"

@implementation MTPaperC10

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperC10 size]; }
+ (CGSize)size { return [MTPaper sizeC10]; }

- (MTPaperType)paperType { return [MTPaperC10 type]; }
+ (MTPaperType)type { return MTPaperTypeC10; };

@end
