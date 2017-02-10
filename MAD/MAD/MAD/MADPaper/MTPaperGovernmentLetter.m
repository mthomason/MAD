//
//  MTPaperGovernmentLetter.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperGovernmentLetter.h"

@implementation MTPaperGovernemntLetter

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperGovernemntLetter size]; }
+ (CGSize)size { return [MTPaper sizeGovernmentLetter]; }

- (MTPaperType)paperType { return [MTPaperGovernemntLetter type]; }
+ (MTPaperType)type { return MTPaperTypeGovernmentLetter; };

@end
