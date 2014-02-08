//
//  MTGraph.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph.h"

@interface MTGraph ()

// MARK: The graph is defined as an adjacency list.
@property (nonatomic, retain) NSMutableArray *vertices;

// MARK: Counters to give edges and verties unique ids.
@property (assign) NSUInteger idUniqueVertices;
@property (assign) NSUInteger idUniqueEdges;

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
        
        [self setIdUniqueEdges:0];
        [self setIdUniqueVertices:0];
    }
    return self;
}

#pragma mark - Members

// MARK: Add new vertex to adjacency list.
- (MTVertex *)addVertexWithObject:(id)object {
    MTVertex *vertex = [[MTVertex alloc] initWithID:[self idUniqueVertices] andObject:object];
    [self setIdUniqueVertices: ([self idUniqueVertices] + 1)];
    [[self vertices] addObject:vertex];
    return [vertex autorelease];
}

// MARK: Add new edge to the graph.
- (MTEdge *)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination object:(id)object andWeight:(NSNumber *)weight {
    
    BOOL result = NO;
    
    // MARK: Create new edge.
    MTEdge *edge = [[MTEdge alloc] initWithUniqueID:@([self idUniqueEdges]) origin:origin destination:destination object:object andWeight:weight];
    [self setIdUniqueEdges: ([self idUniqueEdges] + 1)];

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
            if ([vertex isEqualTo: edgeOrigin]) {
                [vertex addEdge:edge];
                result = YES;
                break;
            }
        }
    }
    [edge autorelease];
    return result ? edge : nil;
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

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root {

    NSNumber *counter = [[NSNumber alloc] initWithInteger:0];

    for (MTVertex *vertex in [self vertices]) {
        [vertex setDfsVertexColor:MTColorWhite];
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:root counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
    for (MTVertex *vertex in [self vertices]) {
        if ([vertex dfsVertexColor] == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    [resultVertices autorelease];
    return [resultEdges autorelease];
}



- (MTLinkedList *)topologicalSortWithError:(NSError **)anError {
    
    NSNumber *counter = @(0);
    
    for (MTVertex *vertex in [self vertices]) {
        [vertex setDfsVertexColor:MTColorWhite];
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:nil counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];

    for (MTVertex *vertex in [self vertices]) {
        if ([vertex dfsVertexColor] == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    
    BOOL isDirectedAcyclicGraph = YES;
    for (MTPair *pair in resultEdges) {
        MTEdgeType edgeType = [[pair latter] integerValue];
        if (edgeType == MTEdgeTypeBackEdge) {
            isDirectedAcyclicGraph = NO;

            if (anError != NULL) {
                *anError = [NSError errorWithDomain: @"MTDataStructures"
                                               code: 1
                                           userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Cycle encountered.", @"Cycle encountered.")}];
            }
            break;
        }
    }

    [resultEdges autorelease];

    [resultVertices reverse];
    
    [resultVertices autorelease];
    return resultVertices;

}

- (void)depthFirstSearchVisitWithCurrentVertex:(MTVertex *)vertex
                                       counter:(NSNumber **)counter
                                   listOfEdges:(MTLinkedList **)listOfEdges
                                listOfVertices:(MTLinkedList **)listOfVertices {
    
    [vertex setDfsVertexColor: MTColorGray];
    *counter = @([(*counter) integerValue] + 1);
    
    [vertex setDfsDistance:*counter];
    [vertex setDfsTimestampDiscovered:*counter];
    
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
        
        MTPair *pairEdge = [[MTPair pairWithFormer:incidentEdge andLatter:@(edgeType)] retain];
        [*listOfEdges add:pairEdge];
        [pairEdge release];
        
        if ([neighborVertex dfsVertexColor] == MTColorWhite) {
            [neighborVertex setDfsPredecessor: vertex];
            [self depthFirstSearchVisitWithCurrentVertex:neighborVertex counter:counter listOfEdges:listOfEdges listOfVertices:listOfVertices];
        }
    }
    
    [vertex setDfsVertexColor:MTColorBlack];
    *counter = @([(*counter) integerValue] + 1);
    [vertex setDfsTimestampFinished:*counter];
    [vertex setDfsFoundCounter:*counter];
    
    MTPair *pairVertices = [[MTPair pairWithFormer:vertex andLatter:*counter] retain];
    [*listOfVertices add:pairVertices];
    [pairVertices release];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    [result appendString:@"--------------------\n"];
    return [result autorelease];
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return [result autorelease];
}

- (NSString *)toStringDebug {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return [result autorelease];
}

@end