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
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSBundle.h>
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTQueue.h"
#import "MTLinkedList.h"
#import "MTPair.h"
#import "MADBfsProperties.h"
#import "MADDfsProperties.h"
#import "MADSortProperties.h"

NSString * const TextCycleEncountered = @"Cycle encountered.";

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
    //id obj = [object copyWithZone:NULL];
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
    NSSet *allEdges = [self allEdges];
    for (MTEdge *existingEdge in allEdges) {
        if ([edge isEqualTo:existingEdge]) {
            edgeExist = YES;
            break;
        }
    }
    
    // MARK: Insert edge.
    if (!edgeExist) {
        NSArray *vertices = self.vertices;
        for (MTVertex *vertex in vertices) {
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
    NSArray *allVertices = [self allVertices];
    for (MTVertex *vertex in allVertices) {
        @autoreleasepool {
            NSArray *ie = [vertex incidentEdges];
            NSArray *incidentEdges = [NSArray arrayWithArray:ie];
            [allEdges addObjectsFromArray:incidentEdges];
        }
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
    NSArray *allVertices = [self allVertices];
    for (MTVertex *vertex in allVertices) {
        @autoreleasepool {
            NSArray *ie = [vertex incidentEdges];
            NSArray *incidentEdges = [NSArray arrayWithArray:ie];
            [allEdges addObjectsFromArray:incidentEdges];
        }
    }
    return allEdges;
}

- (MTVertex *)vertexForObject:(id)object {
    MTVertex *result = nil;
    NSArray *vertices = self.vertices;
    for (MTVertex *vertex in vertices) {
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
        @autoreleasepool {
            MADBfsProperties *bfsp = [[MADBfsProperties alloc] init];
            bfsp.vertexColor = MTColorWhite;
            vertex.properties = bfsp;
        }
    }
    
    MADBfsProperties *bfsp = [[MADBfsProperties alloc] init];
    bfsp.bfsDistance = @(0);
    bfsp.vertexColor = MTColorGray;
    bfsp.bfsPredecessor = nil;
    root.properties = bfsp;
    
    [greyVertices enqueue:root];
    
    do {
        MTVertex *u = [greyVertices dequeue];
        NSArray *incidentEdges = [u incidentEdges];
        for (MTEdge *edge in incidentEdges) {
            MTVertex *vertex = [edge destination];
            do {
                if (vertex.properties.vertexColor == MTColorWhite) {
                    vertex.properties.vertexColor = MTColorGray;
                    vertex.bfsProperties.bfsPredecessor = u;
                    NSNumber *distance = @(u.bfsProperties.bfsDistance.integerValue + 1);
                    vertex.bfsProperties.bfsDistance = distance;
                    [greyVertices enqueue: vertex];
                }
            } while (vertex.properties.vertexColor == MTColorWhite);
        }
        u.properties.vertexColor = MTColorBlack;
        [resultList addObject:u];
    } while (greyVertices.count > 0);
    
    return resultList;
}

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root {
    
    NSNumber *counter = [[NSNumber alloc] initWithInteger:0];
    
    for (MTVertex *vertex in self.vertices) {
        MADDfsProperties *bfsp = [[MADDfsProperties alloc] init];
        bfsp.vertexColor = MTColorWhite;
        vertex.properties = bfsp;
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:root counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
    for (MTVertex *vertex in self.vertices) {
        if (vertex.properties.vertexColor == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    return resultEdges;
}

- (MTLinkedList *)topologicalSortWithError:(NSError **)anError isDirectedAcyclicGraph:(BOOL *)isDirectedAcyclicGraph {
    
    NSNumber *counter = @(0);
    
    NSArray *vertices = self.vertices;
    for (MTVertex *vertex in vertices) {
        @autoreleasepool {
            MADDfsProperties *properties = [[MADDfsProperties alloc] init];
            properties.vertexColor = MTColorWhite;
            vertex.properties = properties;
        }
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:nil counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
    
    for (MTVertex *vertex in self.vertices) {
        if (vertex.properties.vertexColor == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter listOfEdges:&resultEdges listOfVertices:&resultVertices];
        }
    }
    
    *isDirectedAcyclicGraph = YES;
    //BOOL isDirectedAcyclicGraph = YES;
    
    for (MTPair *pair in resultEdges) {
        if ((MTEdgeType)((NSNumber *)pair.latter).unsignedIntegerValue == MTEdgeTypeBackEdge) {
            *isDirectedAcyclicGraph = NO;
            
            if (anError != NULL) {
                NSString *t = NSLocalizedString(TextCycleEncountered, TextCycleEncountered);
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
    
    vertex.properties.vertexColor = MTColorGray;
    
    NSNumber *count = @((*counter).integerValue + 1);
    *counter = count;
    
    vertex.dfsProperties.dfsDistance = *counter;
    vertex.dfsProperties.dfsTimestampDiscovered = *counter;
    
    NSArray *incidentEdges = [vertex incidentEdges];
    for (MTEdge *incidentEdge in incidentEdges) {
        
        MTVertex *neighborVertex = incidentEdge.destination;
        
        MTEdgeType edgeType = MTEdgeTypeCrossEdge;
        if (neighborVertex.properties.vertexColor == MTColorWhite) {
            edgeType = MTEdgeTypeTreeEdge;
        } else if (neighborVertex.properties.vertexColor == MTColorGray) {
            edgeType = MTEdgeTypeBackEdge;
        } else {
            if (vertex.dfsProperties.dfsDistance < neighborVertex.dfsProperties.dfsDistance) {
                edgeType = MTEdgeTypeForwardEdge;
            }
        }
        
        NSNumber *et = @(edgeType);
        MTPair *pairEdge = [MTPair newPairWithFormer:incidentEdge andLatter:et];
        [*listOfEdges add:pairEdge];
        
        if (neighborVertex.properties.vertexColor == MTColorWhite) {
            neighborVertex.dfsProperties.dfsPredecessor = vertex;
            [self depthFirstSearchVisitWithCurrentVertex:neighborVertex counter:counter listOfEdges:listOfEdges listOfVertices:listOfVertices];
        }
    }
    
    vertex.properties.vertexColor = MTColorBlack;
    NSNumber *c2 = @((*counter).integerValue + 1);
    *counter = c2;
    vertex.dfsProperties.dfsTimestampFinished = *counter;
    vertex.dfsProperties.dfsFoundCounter = *counter;
    
    MTPair *pairVertices = [MTPair newPairWithFormer:vertex andLatter:*counter];
    [*listOfVertices add:pairVertices];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    NSArray *allVertices = [self allVertices];
    for (MTVertex *vertex in allVertices) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    [result appendString:@"--------------------\n"];
    return result;
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    NSArray *allVertices = [self allVertices];
    for (MTVertex *vertex in allVertices) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return result;
}

- (NSString *)toStringDebug {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"\n %@\n--------------------\n", self];
    NSArray *allVertices = [self allVertices];
    for (MTVertex *vertex in allVertices) {
        [result appendFormat:@"%@\n", [vertex toStringHumanReadable]];
    }
    return result;
}

@end
