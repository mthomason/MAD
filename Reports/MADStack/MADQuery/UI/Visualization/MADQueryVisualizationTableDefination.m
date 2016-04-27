//
//  MADQueryVisulizationSchemaDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationTableDefination.h"
#import <Foundation/NSCoder.h>
#import <UIKit/UIGeometry.h>

static NSString * const keyCenter = @"c";
static NSString * const keyRoot = @"r";

@implementation MADQueryVisualizationTableDefination

- (instancetype)init {
    if (self = [super init]) {
        self.root = YES;
        self.center = CGPointZero;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _center = [decoder decodeCGPointForKey:keyCenter];
        _root = [decoder decodeBoolForKey:keyRoot];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeCGPoint:_center forKey: keyCenter];
    [coder encodeBool: _root forKey: keyRoot];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MADQueryVisualizationTableDefination *copy = [[[self class] allocWithZone:zone] init];
    copy.center = _center;
    copy.root = _root;
    return copy;
}

+ (instancetype)newTableDefination {
    MADQueryVisualizationTableDefination *tableDefination = [[self alloc] init];
    return tableDefination;
}

@end
