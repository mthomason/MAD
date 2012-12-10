//
//  MTVertex.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTVertex.h"
#import "MTEdge.h"

@interface MTVertex()

@property(nonatomic, retain) id object;                 //Container to hold something
@property(nonatomic, retain) NSMutableArray *edges;     //The edges this node has

@end

@implementation MTVertex

- (id)initWithEdges:(NSSet *)edges {
    return [self initWithEdges:edges andObject:nil];
}

- (id)initWithEdges:(NSSet *)edges andObject:(id)object {
    self = [super init];
    if (self) {
        NSMutableArray *edgesOrdered = [[NSMutableArray alloc] initWithArray:[edges allObjects]];
        [self setEdges:edgesOrdered];
        [edgesOrdered release];

        [self setObject:object];
    }
    return self;
}

- (NSUInteger)numberOfIncidentEdges {
    return [[self edges] count];
}

- (NSSet *)incidentEdges {
    return [NSSet setWithArray: [self edges]];
}

- (void)addEdge:(MTEdge *)edge {
    [[self edges] addObject:edge];
}

- (BOOL)isAdjacentToVertex:(MTVertex *)vertex {
    BOOL result = NO;
    for (MTEdge *edge in [self edges]) {
        if ([[edge destination] isEqual:vertex]) {
            result = YES;
        }
    }
    return result;
}

- (BOOL)isEqual:(id)object {
    BOOL result;
    if (self == object) {
        result = YES;
    } else {
        result = ([[self object] isEqual:[object object]] &&
                  [[self edges] isEqualToArray:[object edges]]);
    }
    return result;
}

- (void)removeEdge:(MTEdge *)edge {
    [[self edges] removeObject: edge];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    result = prime * result + [[self object] hash];
    for (MTVertex *edges in [self edges]) {
        result = prime * result + [edges hash];
    }
    return result;
}

- (void)dealloc {
    if (_object != nil) [_object release];
    [_edges release];
    [super dealloc];
}

@end