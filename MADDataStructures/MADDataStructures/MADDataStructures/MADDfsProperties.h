//
//  MADDfsProperties.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADAlgorithmElementProperties.h"

@class MTVertex;

@interface MADDfsProperties : MADAlgorithmElementProperties

@property (nonatomic, weak)   MTVertex         *dfsPredecessor;
@property (nonatomic, strong) NSNumber         *dfsDistance;
@property (nonatomic, strong) NSNumber         *dfsFoundCounter;
@property (nonatomic, strong) NSNumber         *dfsTimestampDiscovered;
@property (nonatomic, strong) NSNumber         *dfsTimestampFinished;

@end
