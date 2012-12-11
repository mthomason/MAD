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

@interface MTGraph : MTObject

- (id)init;
- (id)initWithVertices:(NSSet *)vertices;

- (void)insertVertex:(MTVertex *)vertex;
- (void)insertEdge:(MTEdge *)edge;

- (void)removeVertex:(MTVertex *)vertex;
- (void)removeEdge:(MTEdge *)edge;

- (NSUInteger)numberOfVertices;
- (NSUInteger)numberOfEdges;

- (NSSet *)allVertices;
- (NSSet *)allEdges;

@end