//
//  MADBfsProperties.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADAlgorithmElementProperties.h"

@class MTVertex;

@interface MADBfsProperties : MADAlgorithmElementProperties

@property (nonatomic, weak)   MTVertex         *bfsPredecessor;
@property (nonatomic, strong) NSNumber         *bfsDistance;

@end
