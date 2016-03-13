//
//  MADDfsProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDfsProperties.h"
#import <Foundation/NSValue.h>

@implementation MADDfsProperties

- (id)copyWithZone:(nullable NSZone *)zone {
    MADDfsProperties *copy = [[[self class] allocWithZone:zone] init];
    copy.vertexColor = self.vertexColor;
    copy.dfsPredecessor = self.dfsPredecessor;
    copy.dfsDistance = [self.dfsDistance copyWithZone:zone];
    copy.dfsFoundCounter = [self.dfsFoundCounter copyWithZone:zone];
    copy.dfsTimestampDiscovered = [self.dfsTimestampDiscovered copyWithZone:zone];
    copy.dfsTimestampFinished = [self.dfsTimestampFinished copyWithZone:zone];
    return copy;
}

@end
