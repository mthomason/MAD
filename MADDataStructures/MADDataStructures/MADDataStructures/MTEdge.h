//
//  MTEdge.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MTEdge_h
#define MAD_DataStructures_MTEdge_h

#import "MTObject.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

typedef NS_ENUM(short, MTEdgeType) {
	MTEdgeTypeTreeEdge,
	MTEdgeTypeBackEdge,
	MTEdgeTypeForwardEdge,
	MTEdgeTypeCrossEdge
};

@class MTVertex;

@interface MTEdge : MTObject
	<NSCopying, MTProtocolLog, MTProtocolCompare>

	@property (nonatomic, weak, readonly) MTVertex *origin;
	@property (nonatomic, weak, readonly) MTVertex *destination;

	@property (readonly, nonatomic, assign, getter=isDirected) BOOL directed;
	@property (nonatomic, assign) MTEdgeType dfsEdgeType;
	@property (nonatomic, strong) NSNumber *weight;

	- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1
					  andDestination:(MTVertex *)vertex2;

	- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1
						 destination:(MTVertex *)vertex2
						   andObject:(id <NSCopying>)object;

	- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1
						 destination:(MTVertex *)vertex2
							  object:(id <NSCopying>)object
						   andWeight:(NSNumber *)weight NS_DESIGNATED_INITIALIZER;

@end

#endif
