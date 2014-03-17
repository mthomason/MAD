//
//  MTEdge.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

typedef NS_ENUM(NSUInteger, MTEdgeType) {
	MTEdgeTypeTreeEdge,
	MTEdgeTypeBackEdge,
	MTEdgeTypeForwardEdge,
    MTEdgeTypeCrossEdge
};

@class MTVertex;

@interface MTEdge : MTObject <MTProtocolLog, MTProtocolCompare>

@property(readonly) BOOL isDirected;

@property(assign) MTEdgeType dfsEdgeType;

- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2;
- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id)object;
- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 object:(id)object andWeight:(NSNumber *)weight;

- (MTVertex *)origin;
- (MTVertex *)destination;

@end