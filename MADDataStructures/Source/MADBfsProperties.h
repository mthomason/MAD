//
//  MADBfsProperties.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MADBfsProperties_h
#define MAD_DataStructures_MADBfsProperties_h

#import <Foundation/NSObject.h>
#import <Foundation/NSValue.h>
#import "MADAlgorithmColor.h"

@class MTVertex;

@interface MADBfsProperties : NSObject <NSCopying>

@property (nonatomic, weak)   MTVertex *bfsPredecessor;
@property (nonatomic, strong) NSNumber *bfsDistance;
@property (nonatomic, assign) MADAlgorithmColor algorithmColor;

@end

#endif
