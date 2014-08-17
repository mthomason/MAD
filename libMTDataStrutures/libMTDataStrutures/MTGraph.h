//
//  MTGraph.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTQueue.h"
#import "MTProtocolLog.h"
#import "MTLinkedList.h"
#import "MTPair.h"

#import "NSNumber+Extras.h"
#import "NSNumber+MTProtocol.h"

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

- (MTVertex *)vertexForObject:(MTObject *)object;

- (NSArray *)breadthFirstSearch:(MTVertex *)root;

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root;

- (MTLinkedList *)topologicalSortWithError:(NSError **)anError;

@end
