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

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

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

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2;
- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id)object;
- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 object:(id)object andWeight:(NSNumber *)weight NS_DESIGNATED_INITIALIZER;

- (MTVertex *)origin;
- (MTVertex *)destination;

@end