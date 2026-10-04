//
//  MTPaperA5.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperB5.h"

@implementation MTPaperB5

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperB5 size]; }
+ (CGSize)size { return [MTPaper sizeB5]; }

- (MTPaperType)paperType { return [MTPaperB5 type]; }
+ (MTPaperType)type { return MTPaperTypeB5; };

@end
