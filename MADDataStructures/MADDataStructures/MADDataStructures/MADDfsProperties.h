//
//  MADDfsProperties.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MADDfsProperties_h
#define MAD_DataStructures_MADDfsProperties_h

#import <Foundation/NSObject.h>
#import "MADAlgorithmColor.h"

@class MTVertex;

@interface MADDfsProperties : NSObject
	<NSCopying>

	@property (nonatomic, weak)   MTVertex         *dfsPredecessor;
	@property (nonatomic, strong) NSNumber         *dfsDistance;
	@property (nonatomic, strong) NSNumber         *dfsFoundCounter;
	@property (nonatomic, strong) NSNumber         *dfsTimestampDiscovered;
	@property (nonatomic, strong) NSNumber         *dfsTimestampFinished;
	@property (nonatomic, assign) MADAlgorithmColor algorithmColor;

@end

#endif
