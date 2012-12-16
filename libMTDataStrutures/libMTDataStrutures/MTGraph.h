//
//  MTGraph.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTQueue.h"
#import "MTProtocolLog.h"
#import "MTLinkedList.h"
#import "MTPair.h"

@interface MTGraph : MTObject <MTProtocolLog>

- (id)init;
- (id)initWithVertices:(NSSet *)vertices;

- (void)insertVertex:(MTVertex *)vertex;
- (BOOL)insertEdge:(MTEdge *)edge;

- (void)removeVertex:(MTVertex *)vertex;
- (void)removeEdge:(MTEdge *)edge;

- (NSUInteger)numberOfVertices;
- (NSUInteger)numberOfEdges;

- (NSArray *)allVertices;
- (NSSet *)allEdges;

- (MTVertex *)vertexForObject:(MTObject *)object;

- (NSArray *)breadthFirstSearch:(MTVertex *)root;
- (NSArray *)depthFirstSearch:(MTVertex *)root;

@end