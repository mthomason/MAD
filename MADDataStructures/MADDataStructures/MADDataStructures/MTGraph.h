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

- (instancetype _Nullable)init;
- (instancetype _Nullable)initWithVertices:(NSSet * _Nullable)vertices NS_DESIGNATED_INITIALIZER;

- (MTVertex * _Null_unspecified)addVertexWithObject:(id _Nullable)object;
- (MTEdge * _Null_unspecified)addEdgeWithOrigin:(MTVertex * _Null_unspecified)origin destination:(MTVertex * _Null_unspecified)destination object:(id _Null_unspecified)object andWeight:(NSNumber * _Null_unspecified)weight;

- (void)removeVertex:(MTVertex * _Null_unspecified)vertex;
- (void)removeEdge:(MTEdge * _Null_unspecified)edge;

- (NSUInteger)numberOfVertices;
- (NSUInteger)numberOfEdges;

- (NSArray * _Null_unspecified)allVertices;
- (nonnull NSSet *)allEdges;

- (MTVertex * _Null_unspecified)vertexForObject:(id _Null_unspecified)object;

- (NSArray * _Null_unspecified)breadthFirstSearch:(MTVertex * _Null_unspecified)root;

- (MTLinkedList * _Null_unspecified)depthFirstSearch:(MTVertex * _Null_unspecified)root;

- (MTLinkedList * _Null_unspecified)topologicalSortWithError:(NSError * _Nullable * _Nullable)anError isDirectedAcyclicGraph:(BOOL * _Nullable)isDirectedAcyclicGraph;

@end

#endif
