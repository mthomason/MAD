//
//  MTPaperA6.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA6.h"

@implementation MTPaperA6

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperA6 size]; }
+ (CGSize)size { return [MTPaper sizeA6]; }

- (MTPaperType)paperType { return [MTPaperA6 type]; }
+ (MTPaperType)type { return MTPaperTypeA6; };

@end
