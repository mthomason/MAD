//
//  MADQueryVisulizationSchemaDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisulizationTableDefination.h"

static NSString * const keyCenter = @"c";
static NSString * const keyDepth = @"d";

@implementation MADQueryVisulizationTableDefination

- (instancetype)initWithRect:(CGRect)rect andDepth:(NSUInteger)depth {
    if (self = [super init]) {
        _depth = depth;
        _center = CGPointMake(rect.origin.x + (rect.size.width / 2.0000f), 100.0000f * (depth + 1));
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _center = [coder decodeCGPointForKey:keyCenter];
        _depth = [coder decodeIntegerForKey:keyDepth];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeCGPoint:_center forKey:keyCenter];
    [coder encodeInteger:_depth forKey:keyDepth];
}

@end
