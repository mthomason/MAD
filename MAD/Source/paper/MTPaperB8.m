//
//  MTPaperA8.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//


#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB8.h"

@implementation MTPaperB8

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperB8 size]; }
+ (CGSize)size { return [MTPaper sizeB8]; }

- (MTPaperType)paperType { return [MTPaperB8 type]; }
+ (MTPaperType)type { return MTPaperTypeB8; };

@end
