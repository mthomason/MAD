//
//  MADAlgorithmElementColor.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADAlgorithmElementProperties.h"

@implementation MADAlgorithmElementProperties

- (id)copyWithZone:(nullable NSZone *)zone {
    MADAlgorithmElementProperties *copy = [[[self class] allocWithZone:zone] init];
    copy.vertexColor = self.vertexColor;
    return copy;
}

@end
