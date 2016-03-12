//
//  MTGraph.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTGraph.h"

@interface MTGraph ()

// MARK: The graph is defined as an adjacency list.
@property (nonatomic, strong) NSMutableArray *vertices;

// MARK: Counters to give edges and verties unique ids.
@property (atomic, assign) NSUInteger idUniqueVertices;
@property (atomic, assign) NSUInteger idUniqueEdges;

@end

@implementation MTGraph

- (void)dealloc {
    [_vertices removeAllObjects];
}

#pragma mark - NSObject Overrides

- (instancetype)init {
    NSSet *set = [NSSet set];
    return [self initWithVertices:set];
}

#pragma mark - Factory

- (instancetype)initWithVertices:(NSSet *)verticesSet {
    if (self = [super init]) {
        NSArray *vertices = verticesSet.allObjects;
        _vertices = [[NSMutableArray alloc] initWithArray:vertices];
        _idUniqueEdges = 0;
        _idUniqueVertices = 0;
    }
    return self;
}

#pragma mark - Members

// MARK: Add new vertex to adjacency list.
- (MTVertex *)addVertexWithObject:(id <NSCopying>)object {
    MTVertex *vertex = [[MTVertex alloc] initWithID:self.idUniqueVertices andObject:object];
    self.idUniqueVertices = (self.idUniqueVertices + 1);
    [self.vertices addObject:vertex];
    return vertex;
}

// MARK: Add new edge to the graph.
- (MTEdge *)addEdgeWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination object:(id <NSCopying>)object andWeight:(NSNumber *)weight {
    
    BOOL result = NO;
    
    // MARK: Create new edge.
    NSNumber *uniqueId = @(self.idUniqueEdges);
    MTEdge *edge = [[MTEdge alloc] initWithUniqueID:uniqueId origin:origin destination:destination object:object andWeight:weight];
    self.idUniqueEdges = self.idUniqueEdges + 1;

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
        for (MTVertex *vertex in self.vertices) {
            MTVertex *edgeOrigin = edge.origin;
            if ([vertex isEqualTo: edgeOrigin]) {
                [vertex addEdge:edge];
                result = YES;
                break;
            }
        }
    }
    return result ? edge : nil;
}

- (void)removeVertex:(MTVertex *)vertex {
    [self.vertices removeObject: vertex];
}

- (void)removeEdge:(MTEdge *)edge {
    for (MTVertex *vertex in self.vertices) {
        [vertex removeEdge:edge];
    }
}

- (NSUInteger)numberOfVertices {
    return self.vertices.count;
}

- (NSUInteger)numberOfEdges {
    NSMutableSet *allEdges = [[NSMutableSet alloc] init];
    for (MTVertex *vertex in [self allVertices]) {
        [allEdges addObjectsFromArray:[vertex incidentEdges]];
    }
    return allEdges.count;
}

- (NSArray *)allVertices {
    NSArray *results;
    @synchronized(self) {
        results = self.vertices;
    }
    return results;
}

- (NSSet *)allEdges {
    NSMutableSet *allEdges = [[NSMutableSet alloc] init];
    for (MTVertex *vertex in [self allVertices]) {
        [allEdges addObjectsFromArray:[vertex incidentEdges]];
    }
    return allEdges;
}

- (MTVertex *)vertexForObject:(id)object {
    MTVertex *result = nil;
    for (MTVertex *vertex in self.vertices) {
        if ([vertex.object isEqual: object]) {
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
    for (MTVertex *vertex in self.vertices) {
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
    
    return resultList;
}

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root {

    NSNumber *counter = [[NSNumber alloc] initWithInteger:0];

    for (MTVertex *vertex in self.vertices) {
        [vertex setDfsVertexColor:MTColorWhite];
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:root counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
    for (MTVertex *vertex in self.vertices) {
        if ([vertex dfsVertexColor] == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    return resultEdges;
}



- (MTLinkedList *)topologicalSortWithError:(NSError **)anError isDirectedAcyclicGraph:(BOOL *)isDirectedAcyclicGraph {
    
    NSNumber *counter = @(0);
    
    for (MTVertex *vertex in self.vertices) {
        [vertex setDfsVertexColor:MTColorWhite];
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:nil counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];

    for (MTVertex *vertex in self.vertices) {
        if (vertex.dfsVertexColor == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    
    *isDirectedAcyclicGraph = YES;
    //BOOL isDirectedAcyclicGraph = YES;
    for (MTPair *pair in resultEdges) {
        MTEdgeType edgeType = [pair.latter unsignedIntegerValue];
        if (edgeType == MTEdgeTypeBackEdge) {
            *isDirectedAcyclicGraph = NO;

            if (anError != NULL) {
                NSString *t = NSLocalizedString(@"Cycle encountered.", @"Cycle encountered.");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : t};
                *anError = [NSError errorWithDomain: @"MTDataStructures"
                                               code: 1
                                           userInfo: userInfo];
            }
            break;
        }
    }

    [resultVertices reverse];
    return resultVertices;

}

- (void)depthFirstSearchVisitWithCurrentVertex:(MTVertex *)vertex
                                       counter:(NSNumber **)counter
                                   listOfEdges:(MTLinkedList **)listOfEdges
                                listOfVertices:(MTLinkedList **)listOfVertices {
    
    vertex.dfsVertexColor = MTColorGray;

    NSNumber *count = @((*counter).integerValue + 1);
    *counter = count;
    
    vertex.dfsDistance = *counter;
    vertex.dfsTimestampDiscovered = *counter;
    
    for (MTEdge *incidentEdge in [vertex incidentEdges]) {
        
        MTVertex *neighborVertex = incidentEdge.destination;

        MTEdgeType edgeType = MTEdgeTypeCrossEdge;
        if (neighborVertex.dfsVertexColor == MTColorWhite) {
            edgeType = MTEdgeTypeTreeEdge;
        } else if (neighborVertex.dfsVertexColor == MTColorGray) {
            edgeType = MTEdgeTypeBackEdge;
        } else {
            if (vertex.dfsDistance < neighborVertex.dfsDistance) {
                edgeType = MTEdgeTypeForwardEdge;
            }
        }

        NSNumber *et = @(edgeType);
        MTPair *pairEdge = [MTPair pairWithFormer:incidentEdge andLatter:et];
        [*listOfEdges add:pairEdge];
        
        if ([neighborVertex dfsVertexColor] == MTColorWhite) {
            [neighborVertex setDfsPredecessor: vertex];
            [self depthFirstSearchVisitWithCurrentVertex:neighborVertex counter:counter listOfEdges:listOfEdges listOfVertices:listOfVertices];
        }
    }
    
    vertex.dfsVertexColor = MTColorBlack;
    NSNumber *c2 = @((*counter).integerValue + 1);
    *counter = c2;
    vertex.dfsTimestampFinished = *counter;
    vertex.dfsFoundCounter = *counter;
    
    MTPair *pairVertices = [MTPair pairWithFormer:vertex andLatter:*counter];
    [*listOfVertices add:pairVertices];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    [result appendString:@"--------------------\n"];
    return result;
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return result;
}

- (NSString *)toStringDebug {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    for (MTVertex *vertex in [self allVertices]) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return result;
}

@end
