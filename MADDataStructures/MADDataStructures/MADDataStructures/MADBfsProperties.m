//
//  MADBfsProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADBfsProperties.h"
#import <Foundation/NSValue.h>
@implementation MADBfsProperties

- (id)copyWithZone:(nullable NSZone *)zone {
    MADBfsProperties *copy = [[[self class] allocWithZone:zone] init];
    copy.bfsDistance = [self.bfsDistance copyWithZone:zone];
    copy.bfsPredecessor = self.bfsPredecessor;
    copy.vertexColor = self.vertexColor;
    return copy;
}

@end
