//
//  MTPaperA1.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperC1.h"

@implementation MTPaperC1

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperC1 size]; }
+ (CGSize)size { return [MTPaper sizeC1]; }

- (MTPaperType)paperType { return [MTPaperC1 type]; }
+ (MTPaperType)type { return MTPaperTypeC1; };

@end
