//
//  MADSortProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSortProperties.h"

@implementation MADSortProperties

- (id)copyWithZone:(NSZone *)zone {
	typeof(self) copy = [[self.class allocWithZone:zone] init];
	copy.algorithmColor = _algorithmColor;
	return copy;
}

@end
