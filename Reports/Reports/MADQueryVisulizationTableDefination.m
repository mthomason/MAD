//
//  MADQueryVisulizationSchemaDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisulizationTableDefination.h"

static NSString * const keyCenter = @"c";
static NSString * const keyRoot = @"r";

@implementation MADQueryVisulizationTableDefination

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _center = [decoder decodeCGPointForKey:keyCenter];
        _root = [decoder decodeIntegerForKey:keyRoot];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeCGPoint:_center forKey:keyCenter];
    [coder encodeInteger:_root forKey:keyRoot];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MADQueryVisulizationTableDefination *result = [[[self class] allocWithZone:zone] init];
    result.center = self.center;
    result.root = self.root;
    return result;
}

@end
