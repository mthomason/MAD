//
//  MTGraph.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MTGraph_MTObject_h
#define MAD_MTGraph_MTObject_h

#import <MADDataStructures/MTObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSError.h>
#import <Foundation/NSValue.h>

@class MTVertex, MTEdge, MTLinkedList;

@interface MTGraph : MTObject

	- (instancetype)init;
	- (instancetype)initWithVertices:(NSSet *)vertices NS_DESIGNATED_INITIALIZER;

	- (MTVertex *)addVertexWithObject:(NSObject <NSCopying> *)object;
	- (MTEdge *)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination
						   object:(id <NSCopying>)object andWeight:(NSNumber *)weight;

	- (void)removeVertex:(MTVertex *)vertex;
	- (void)removeEdge:(MTEdge *)edge;

	- (NSUInteger)numberOfVertices;
	- (NSUInteger)numberOfEdges;

	- (NSArray *)allVertices;
	- (NSSet *)allEdges;

	- (MTVertex *)vertexForObject:(id)object;

	- (NSArray *)breadthFirstSearch:(MTVertex *)root;

	- (MTLinkedList *)depthFirstSearch:(MTVertex *)root;

	- (NSArray *)standardTopologicalSortWithError:(NSError * __autoreleasing *)error;

	// This version is optimized for use inside MADDesigner, but may not return expected results.
	- (MTLinkedList *)topologicalSortWithError:(NSError * __autoreleasing *)anError
						isDirectedAcyclicGraph:(BOOL *)isDirectedAcyclicGraph;


@end

#endif
