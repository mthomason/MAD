//
//  MADSortProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADSortProperties.h"

@implementation MADSortProperties

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class allocWithZone:zone] init];
    copy.algorithmColor = _algorithmColor;
    return copy;
}

@end
