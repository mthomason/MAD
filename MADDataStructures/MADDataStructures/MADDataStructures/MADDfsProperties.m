//
//  MADDfsProperties.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDfsProperties.h"
#import <Foundation/NSValue.h>

@implementation MADDfsProperties

- (id)copyWithZone:(NSZone *)zone {
	typeof(self) copy = [[self.class allocWithZone:zone] init];
	copy.dfsPredecessor = _dfsPredecessor;
	copy.dfsDistance = [_dfsDistance copyWithZone:zone];
	copy.dfsFoundCounter =[_dfsFoundCounter copyWithZone:zone];
	copy.dfsTimestampDiscovered = [_dfsTimestampDiscovered copyWithZone:zone];
	copy.dfsTimestampFinished = [_dfsTimestampFinished copyWithZone:zone];
	copy.algorithmColor = _algorithmColor;
	return copy;
}

@end
