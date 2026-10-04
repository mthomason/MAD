//
//  MTPaperA0.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperC0.h"

@implementation MTPaperC0

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperC0 size]; }
+ (CGSize)size { return [MTPaper sizeC0]; }

- (MTPaperType)paperType { return [MTPaperC0 type]; }
+ (MTPaperType)type { return MTPaperTypeC0; };

@end
