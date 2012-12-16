//
//  MTGraph.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph.h"

@interface MTGraph ()

@property (retain) NSMutableArray *vertices;

@end

@implementation MTGraph

#pragma mark - NSObject Overrides

- (void)dealloc {
    [_vertices release];
    [super dealloc];
}

- (id)init {
    return [self initWithVertices:[NSSet set]];
}

#pragma mark - Factory

- (id)initWithVertices:(NSSet *)verticesSet {
    self = [super init];
    if (self) {
        NSMutableArray *vertices = [[NSMutableArray alloc] initWithArray: [verticesSet allObjects]];
        [self setVertices: vertices];
        [vertices release];
    }
    return self;
}

#pragma mark - Members

- (void)insertVertex:(MTVertex *)newVertex {
    BOOL duplicate = NO;
    for (MTVertex *vertex in [self vertices]) {
        if (![newVertex isEqualTo:vertex]) {
            duplicate = YES;
            break;
        }
    }
    if (!duplicate) {
        [[self vertices] addObject:newVertex];
    }
}

- (void)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination andObject:(id)object {
    MTEdge *edge = [[MTEdge alloc] initWithOrigin:origin destination:destination andObject:object];
    [self insertEdge:edge];
    [edge release];
}

// ???: What happens with malformated edges?
- (BOOL)insertEdge:(MTEdge *)edge {
    BOOL result = NO;
    
    // MARK: Make sure edge does not exist.
    BOOL edgeExist = NO;
    for (MTEdge *existingEdge in [self allEdges]) {
        if ([edge isEqualTo:existingEdge]) {
            edgeExist = YES;
            break;
        }
    }

    // MARK: Insert edge.
    if (!edgeExist) {
        for (MTVertex *vertex in [self vertices]) {
            MTVertex *edgeOrigin = [edge origin];
            NSLog(@"edgeOrigin: %@", edgeOrigin);
            if ([vertex isEqual:[edge origin]]) {
                [vertex addEdge:edge];
                result = YES;
                break;
            }
        }
    }

    return result;
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
        [allEdges addObjectsFromArray:[vertex incidentEdges]];
    }
    NSUInteger result = [allEdges count];
    [allEdges release];
    return result;
}

- (NSArray *)allVertices {
    NSArray *results;
    @synchronized(self) {
        results = [[[self vertices] retain] autorelease];
    }
    return results;
}

- (NSSet *)allEdges {
    NSMutableSet *allEdges = [[NSMutableSet alloc] init];
    for (MTVertex *vertex in [self allVertices]) {
        [allEdges addObjectsFromArray:[vertex incidentEdges]];
    }
    return [allEdges autorelease];
}

- (MTVertex *)vertexForObject:(MTObject *)object {
    MTVertex *result = nil;
    for (MTVertex *vertex in [self vertices]) {
        if ([[vertex object] isEqual: object]) {
            result = vertex;
            break;
        }
    }
    return result;
}

// MARK: Breadth first search returns a breadth first tree
- (NSArray *)breadthFirstSearch:(MTVertex *)root {
    NSMutableArray *resultList = [[NSMutableArray alloc] init];
    
    MTQueue *greyVertices = [[MTQueue alloc] init];
    for (MTVertex *vertex in [self vertices]) {
        [vertex setBfsVertexColor:MTColorWhite];
    }
    [root setBfsDistance:@(0)];
    [root setBfsVertexColor:MTColorGray];
    [root setBfsPredecessor:nil];
    
    [greyVertices enqueue:root];

    do {
        MTVertex *u = [greyVertices dequeue];
        NSArray *incidentEdges = [u incidentEdges];
        for (MTEdge *edge in incidentEdges) {
            MTVertex *vertex = [edge destination];
            do {
                if ([vertex bfsVertexColor] == MTColorWhite) {
                    [vertex setBfsVertexColor: MTColorGray];
                    [vertex setBfsPredecessor: u];
                    [vertex setBfsDistance:@([[u bfsDistance] integerValue] + 1)];
                    [greyVertices enqueue: vertex];
                }
            } while ([vertex bfsVertexColor] == MTColorWhite);
        }
        [u setBfsVertexColor:MTColorBlack];
        [resultList addObject:u];
    } while ([greyVertices count] > 0);
    
    [greyVertices release];
    
    return [resultList autorelease];
}

- (NSArray *)depthFirstSearch:(MTVertex *)root {

    NSNumber *counter = [[NSNumber alloc] initWithInteger:0];

    for (MTVertex *vertex in [self vertices]) {
        [vertex setBfsVertexColor:MTColorWhite];
    }
    
    MTLinkedList *edges = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:root counter:&counter list:&edges];
    for (MTVertex *vertex in [self vertices]) {
        if ([vertex dfsVertexColor] == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter list:&edges];
        }
    }
    
    [edges release];
    
    return nil;
}

- (void)depthFirstSearchVisitWithCurrentVertex:(MTVertex *)vertex
                                       counter:(NSNumber **)counter
                                          list:(MTLinkedList **)list {
    
    [vertex setDfsVertexColor: MTColorGray];
    *counter = @([(*counter) integerValue] + 1);
    
    [vertex setDfsDistance:*counter];
    
    for (MTEdge *incidentEdge in [vertex incidentEdges]) {
        
        MTVertex *neighborVertex = [incidentEdge destination];

        MTEdgeType edgeType = MTEdgeTypeCrossEdge;
        if ([neighborVertex dfsVertexColor] == MTColorWhite) {
            edgeType = MTEdgeTypeTreeEdge;
        } else if ([neighborVertex dfsVertexColor] == MTColorGray) {
            edgeType = MTEdgeTypeBackEdge;
        } else {
            if ([vertex dfsDistance] < [neighborVertex dfsDistance]) {
                edgeType = MTEdgeTypeForwardEdge;
            }
        }
        
        [*list insert:[MTPair pairWithFormer:incidentEdge andLatter:@(edgeType)]];
        
        if ([neighborVertex dfsVertexColor] == MTColorWhite) {
            [neighborVertex setDfsPredecessor: vertex];
            [self depthFirstSearchVisitWithCurrentVertex:neighborVertex counter:counter list:list];
        }
    }
    
    [vertex setDfsVertexColor:MTColorBlack];
    *counter = @([(*counter) integerValue] + 1);
    [vertex setDfsFoundCounter:*counter];
}

#pragma mark - MTProtocolLog

- (NSString *)humanReadableObjectIdentifier {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex humanReadableObjectIdentifier]];
    }
    NSLog(@"%@--------------------\n", result);
    return [result autorelease];
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex humanReadableObjectIdentifier]];
    }
    NSLog(@"%@\n--------------------\n", result);
    return [result autorelease];
}

- (NSString *)toStringForDebugging {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex humanReadableObjectIdentifier]];
    }
    NSLog(@"%@\n--------------------\n", result);
    return [result autorelease];
}

@end