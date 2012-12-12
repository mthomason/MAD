//
//  MTVertex.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"

typedef enum {
	MTColorBlack,
	MTColorWhite,
	MTColorGray
} MTAlgorithmColor;

@class MTEdge;

@interface MTVertex : MTObject

- (id)initWithEdges:(NSSet *)edges;
- (id)initWithEdges:(NSSet *)edges andObject:(id)object;

- (void)addEdge:(MTEdge *)edge;

- (NSUInteger)numberOfIncidentEdges;
- (NSArray *)incidentEdges;
- (void)removeEdge:(MTEdge *)edge;
- (BOOL)isAdjacentToVertex:(MTVertex *)vertex;

@property (assign)   MTAlgorithmColor bfsVertexColor;
@property (retain) MTVertex *bfsPredecessor;
@property (retain) NSNumber *bfsDistance;

- (void)setBfsVertexColor:(MTAlgorithmColor)bfsVertexColor;
- (void)setBfsPredecessor:(MTVertex *)bfsPredecessor;
- (void)setBfsDistance:(NSNumber *)bfsDistance;

@end