//
//  MADSortProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADSortProperties.h"

@implementation MADSortProperties

- (id)copyWithZone:(nullable NSZone *)zone {
    MADSortProperties *copy = [[[self class] allocWithZone:zone] init];
    copy.vertexColor = self.vertexColor;
    return copy;
}

@end
