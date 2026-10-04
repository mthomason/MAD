//
//  MTPaperLegal.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperLegal.h"

@implementation MTPaperLegal

- (instancetype)init {
	if (self = [super init]) { }
	return self;
}

- (CGSize)paperSize { return [MTPaperLegal size]; }
+ (CGSize)size { return [MTPaper sizeLegal]; }

- (MTPaperType)paperType { return [MTPaperLegal type]; }
+ (MTPaperType)type { return MTPaperTypeLegal; };

@end
