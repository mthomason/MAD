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

#import "MTPaperC5.h"

@implementation MTPaperC5

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperC5 size]; }
+ (CGSize)size { return [MTPaper sizeC5]; }

- (MTPaperType)paperType { return [MTPaperC5 type]; }
+ (MTPaperType)type { return MTPaperTypeC5; };

@end
