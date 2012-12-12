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

@interface MTGraph : MTObject

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

- (MTGraph *)breadthFirstSearch:(MTVertex *)vertexSource;

- (NSString *)graphToString;

@end