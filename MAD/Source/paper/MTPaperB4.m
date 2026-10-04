//
//  MTPaperA4.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB4.h"

@implementation MTPaperB4

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperB4 size]; }
+ (CGSize)size { return [MTPaper sizeB4]; }

- (MTPaperType)paperType { return [MTPaperB4 type]; }
+ (MTPaperType)type { return MTPaperTypeB4; };

@end
