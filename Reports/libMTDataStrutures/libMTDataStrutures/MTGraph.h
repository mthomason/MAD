//
//  MTGraph.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTGraph_MTObject_h
#define MAD_MTGraph_MTObject_h

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTQueue.h"
#import "MTProtocolLog.h"
#import "MTLinkedList.h"
#import "MTPair.h"

@interface MTGraph : MTObject <MTProtocolLog>

- (instancetype)init;
- (instancetype)initWithVertices:(NSSet *)vertices NS_DESIGNATED_INITIALIZER;

- (MTVertex *)addVertexWithObject:(id)object;
- (MTEdge *)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination object:(id)object andWeight:(NSNumber *)weight;

- (void)removeVertex:(MTVertex *)vertex;
- (void)removeEdge:(MTEdge *)edge;

- (NSUInteger)numberOfVertices;
- (NSUInteger)numberOfEdges;

- (NSArray *)allVertices;
- (NSSet *)allEdges;

- (MTVertex *)vertexForObject:(id)object;

- (NSArray *)breadthFirstSearch:(MTVertex *)root;

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root;

- (MTLinkedList *)topologicalSortWithError:(NSError **)anError isDirectedAcyclicGraph:(BOOL *)isDirectedAcyclicGraph;

@end

#endif
