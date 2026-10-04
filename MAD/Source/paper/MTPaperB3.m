//
//  MTPaperA3.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB3.h"

@implementation MTPaperB3

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperB3 size]; }
+ (CGSize)size { return [MTPaper sizeB3]; }

- (MTPaperType)paperType { return [MTPaperB3 type]; }
+ (MTPaperType)type { return MTPaperTypeB3; };

@end
