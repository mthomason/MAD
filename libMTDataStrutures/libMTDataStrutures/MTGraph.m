//
//  MTGraph.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph.h"

@interface MTGraph ()

@property(nonatomic, retain) NSMutableArray *vertices;

@end

@implementation MTGraph

- (void)dealloc {
    [_vertices release];
    [super dealloc];
}

- (id)init {
    return [self initWithVertices:[NSSet set]];
}

- (id)initWithVertices:(NSSet *)verticesSet {
    self = [super init];
    if (self) {

        NSMutableArray *vertices = [[NSMutableArray alloc] initWithArray: [verticesSet allObjects]];
        [self setVertices: vertices];
        [vertices release];

    }
    return self;
}

- (void)insertVertex:(MTVertex *)newVertex {
    [[self vertices] addObject:newVertex];
}

- (void)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination andObject:(id)object {
    MTEdge *edge = [[MTEdge alloc] initWithOrigin:origin destination:destination andObject:object];
    [self insertEdge:edge];
}

- (void)insertEdge:(MTEdge *)edge {
    for (MTVertex *vertex in [self vertices]) {
        if ([vertex isEqual:[edge origin]]) {
            [vertex addEdge:edge];
            break;
        }
    }    
}

- (void)removeVertex:(MTVertex *)vertex {
    [[self vertices] removeObject: vertex];
}
- (void)removeEdge:(MTEdge *)edge {
    for (MTVertex *vertex in [self vertices]) {
        [vertex removeEdge:edge];
    }
}

- (NSUInteger)numberOfVertices {
    return [[self vertices] count];
}

- (NSUInteger)numberOfEdges {
    NSMutableSet *allEdges = [[NSMutableSet alloc] init];
    for (MTVertex *vertex in [self allVertices]) {
        [allEdges addObjectsFromArray:[[vertex incidentEdges] allObjects]];
    }
    NSUInteger result = [allEdges count];
    [allEdges release];
    return result;
}

- (NSSet *)allVertices {
    return [NSSet setWithArray: [self vertices]];
}

- (NSSet *)allEdges {
    NSMutableSet *allEdges = [[NSMutableSet alloc] init];
    for (MTVertex *vertex in [self allVertices]) {
        [allEdges addObjectsFromArray:[[vertex incidentEdges] allObjects]];
    }
    return [allEdges autorelease];
}

@end