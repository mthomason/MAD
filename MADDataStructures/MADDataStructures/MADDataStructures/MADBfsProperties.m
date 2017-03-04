//
//  MADBfsProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBfsProperties.h"
#import <Foundation/NSValue.h>

@implementation MADBfsProperties

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class allocWithZone:zone] init];
    copy.bfsDistance = [_bfsDistance copyWithZone:zone];
    copy.bfsPredecessor = _bfsPredecessor;
    copy.algorithmColor = _algorithmColor;
    return copy;
}

@end
