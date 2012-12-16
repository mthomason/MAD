//
//  MTVertex.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTProtocolLog.h"

typedef NS_ENUM(NSUInteger, MTAlgorithmColor) {
	MTColorBlack,
	MTColorWhite,
	MTColorGray
};

@class MTEdge;

@interface MTVertex : MTObject <MTProtocolLog>

- (id)initWithEdges:(NSSet *)edges;
- (id)initWithEdges:(NSSet *)edges andObject:(id)object;

- (void)addEdge:(MTEdge *)edge;

- (NSUInteger)numberOfIncidentEdges;
- (NSArray *)incidentEdges;
- (void)removeEdge:(MTEdge *)edge;
- (BOOL)isAdjacentToVertex:(MTVertex *)vertex;

@property (assign) MTAlgorithmColor bfsVertexColor;
@property (retain) MTVertex         *bfsPredecessor;
@property (retain) NSNumber         *bfsDistance;

@property (assign) MTAlgorithmColor dfsVertexColor;
@property (retain) NSNumber         *dfsDistance;
@property (retain) MTVertex         *dfsPredecessor;
@property (retain) NSNumber         *dfsFoundCounter;

- (void)setBfsVertexColor:(MTAlgorithmColor)bfsVertexColor;
- (void)setBfsPredecessor:(MTVertex *)bfsPredecessor;
- (void)setBfsDistance:(NSNumber *)bfsDistance;

@end