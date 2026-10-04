//
//  MTPaperA7.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperA7.h"

@implementation MTPaperA7

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperA7 size]; }
+ (CGSize)size { return [MTPaper sizeA7]; }

- (MTPaperType)paperType { return [MTPaperA7 type]; }
+ (MTPaperType)type { return MTPaperTypeA7; };

@end
