//
//  MTGraph.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
#import "MADAlgorithmColor.h"
#import "MADAlgorithmElementProperties.h"

NSString * const TextCycleEncountered = @"Cycle encountered.";

@interface MTGraph ()

    // MARK: The graph is defined as an adjacency list.
    @property (nonatomic, strong) NSMutableArray <MTVertex *> *vertices;

    // MARK: Counters to give edges and verties unique ids.
    @property (nonatomic, assign) NSUInteger idUniqueVertices;
    @property (nonatomic, assign) NSUInteger idUniqueEdges;

@end

@implementation MTGraph

- (void)dealloc {
    [_vertices removeAllObjects];
}

#pragma mark - NSObject Overrides

- (instancetype)init {
    NSSet *set = [[NSSet alloc] init];
    return [self initWithVertices:set];
}

#pragma mark - Factory

- (instancetype)initWithVertices:(NSSet *)verticesSet {
    if (self = [super init]) {
        if (verticesSet.count) {
            NSArray *vertices = verticesSet.allObjects;
            _vertices = [[NSMutableArray alloc] initWithArray:vertices];

        } else {
            _vertices = [[NSMutableArray alloc] init];
        }
        _idUniqueEdges = 0;
        _idUniqueVertices = 0;
    }
    return self;
}

#pragma mark - Members

// MARK: Add new vertex to adjacency list.
- (MTVertex *)addVertexWithObject:(NSObject <NSCopying> *)object {
    id obj = [object copy];
    MTVertex *vertex = [[MTVertex alloc] initWithID: self.idUniqueVertices
                                          andObject: obj];
    self.idUniqueVertices = (self.idUniqueVertices + 1);
    [self.vertices addObject:vertex];
    return vertex;
}

// MARK: Add new edge to the graph.
- (MTEdge *)addEdgeWithOrigin:(MTVertex *)origin
                  destination:(MTVertex *)destination
                       object:(id <NSCopying>)object
                    andWeight:(NSNumber *)weight {
    
    BOOL result = NO;
    
    // MARK: Create new edge.
    NSNumber *uniqueId = [[NSNumber alloc] initWithUnsignedInteger:_idUniqueEdges];
    MTEdge *edge = [[MTEdge alloc] initWithUniqueID: uniqueId
                                             origin: origin
                                        destination: destination
                                             object: object
                                          andWeight: weight];
    _idUniqueEdges++;

    // MARK: Make sure edge does not exist.
    BOOL edgeExist = NO;
    NSSet *allEdges = [self allEdges];
    MTEdge *existingEdge;
    for (existingEdge in allEdges) {
        if ([edge isEqualTo:existingEdge]) {
            edgeExist = YES;
            break;
        }
    }
    
    // MARK: Insert edge.
    if (!edgeExist) {
        NSArray *vertices = self.vertices;
        MTVertex *vertex, *edgeOrigin;
        for (vertex in vertices) {
            edgeOrigin = edge.origin;
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
            NSArray *ie = vertex.incidentEdges;
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
            NSArray *ie = vertex.incidentEdges;
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
        vertex.properties.algorithmColor = MTColorWhite;
    }
    
    //MADBfsProperties *bfsp = [[MADBfsProperties alloc] init];
    //bfsp.bfsDistance = @(0);
    //bfsp.algorithmColor = MTColorGray;
    //bfsp.bfsPredecessor = nil;
    //root.properties = bfsp;

    root.bfsProperties.bfsPredecessor = nil;
    root.properties.algorithmColor = MTColorGray;
    root.bfsProperties.bfsDistance = @(0);
    
    [greyVertices enqueue:root];
    
    do {
        MTVertex *u = [greyVertices dequeue];
        NSArray *incidentEdges = u.incidentEdges;
        NSNumber *distance;
        for (MTEdge *edge in incidentEdges) {
            MTVertex *vertex = edge.destination;
            do {
                if (vertex.properties.algorithmColor == MTColorWhite) {
                    vertex.properties.algorithmColor = MTColorGray;
                    vertex.bfsProperties.bfsPredecessor = u;
                    distance = [[NSNumber alloc] initWithInteger:u.bfsProperties.bfsDistance.integerValue + 1];
                    vertex.bfsProperties.bfsDistance = distance;
                    [greyVertices enqueue: vertex];
                }
            } while (vertex.properties.algorithmColor == MTColorWhite);
        }
        u.properties.algorithmColor = MTColorBlack;
        [resultList addObject:u];
    } while (greyVertices.count > 0);
    
    return resultList;
}

- (MTLinkedList *)depthFirstSearch:(MTVertex *)root {
    
    NSNumber *counter = [[NSNumber alloc] initWithInteger:0];
    
    for (MTVertex *vertex in self.vertices) {
        vertex.properties.algorithmColor = MTColorWhite;
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:root counter:&counter
                                     listOfEdges:&resultEdges listOfVertices:&resultVertices];
    for (MTVertex *vertex in self.vertices) {
        if (vertex.properties.algorithmColor == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex:vertex counter:&counter
                                             listOfEdges:&resultEdges
                                          listOfVertices:&resultVertices];
        }
    }
    return resultEdges;
}

- (MTLinkedList *)topologicalSortWithError:(NSError * __autoreleasing *)anError
                    isDirectedAcyclicGraph:(BOOL *)isDirectedAcyclicGraph {
    
    NSNumber *counter = @0;
    
    NSArray *vertices = self.vertices;
    for (MTVertex *vertex in vertices) {
        vertex.properties.algorithmColor = MTColorWhite;
    }
    
    MTLinkedList *resultEdges = [[MTLinkedList alloc] init];
    MTLinkedList *resultVertices = [[MTLinkedList alloc] init];
    
    [self depthFirstSearchVisitWithCurrentVertex:nil
                                         counter:&counter
                                     listOfEdges:&resultEdges
                                  listOfVertices:&resultVertices];
    
    for (MTVertex *vertex in self.vertices) {
        if (vertex.properties.algorithmColor == MTColorWhite) {
            [self depthFirstSearchVisitWithCurrentVertex: vertex
                                                 counter: &counter
                                             listOfEdges: &resultEdges
                                          listOfVertices: &resultVertices];
        }
    }
    
    *isDirectedAcyclicGraph = YES;
    //BOOL isDirectedAcyclicGraph = YES;
    
    for (MTPair *pair in resultEdges) {
        if ((MTEdgeType)((NSNumber *)pair.latter).shortValue == MTEdgeTypeBackEdge) {
            *isDirectedAcyclicGraph = NO;
            
            /*if (anError != NULL) {
                NSString *t = NSLocalizedString(TextCycleEncountered, TextCycleEncountered);
                NSDictionary *userInfo;
                userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:t, NSLocalizedDescriptionKey, nil];
                *anError = [NSError errorWithDomain: @"MTDataStructures"
                                               code: 1
                                           userInfo: userInfo];
            }*/
            break;
        }
    }
    
    [resultVertices reverse];
    return resultVertices;
    
}

- (void)depthFirstSearchVisitWithCurrentVertex:(MTVertex *)vertex
                                       counter:(NSNumber * __autoreleasing *)counter
                                   listOfEdges:(MTLinkedList * __autoreleasing *)listOfEdges
                                listOfVertices:(MTLinkedList * __autoreleasing *)listOfVertices {
    
    vertex.properties.algorithmColor = MTColorGray;
    
    NSNumber *count = [[NSNumber alloc] initWithInteger:(*counter).integerValue + 1];
    *counter = count;
    
    vertex.dfsProperties.dfsDistance = *counter;
    vertex.dfsProperties.dfsTimestampDiscovered = *counter;
    
    NSArray *incidentEdges = vertex.incidentEdges;
    for (MTEdge *incidentEdge in incidentEdges) {
        
        MTVertex *neighborVertex = incidentEdge.destination;
        
        MTEdgeType edgeType = MTEdgeTypeCrossEdge;
        if (neighborVertex.properties.algorithmColor == MTColorWhite) {
            edgeType = MTEdgeTypeTreeEdge;
        } else if (neighborVertex.properties.algorithmColor == MTColorGray) {
            edgeType = MTEdgeTypeBackEdge;
        } else {
            if (vertex.dfsProperties.dfsDistance < neighborVertex.dfsProperties.dfsDistance) {
                edgeType = MTEdgeTypeForwardEdge;
            }
        }
        
        NSNumber *et = [[NSNumber alloc] initWithShort:edgeType];
        if (incidentEdge != nil) {
            MTPair *pairEdge = [MTPair newPairWithFormer:incidentEdge andLatter:et];
            [*listOfEdges add:pairEdge];
        }
        
        if (neighborVertex.properties.algorithmColor == MTColorWhite) {
            neighborVertex.dfsProperties.dfsPredecessor = vertex;
            [self depthFirstSearchVisitWithCurrentVertex: neighborVertex
                                                 counter: counter
                                             listOfEdges: listOfEdges
                                          listOfVertices: listOfVertices];
        }
    }
    
    vertex.properties.algorithmColor = MTColorBlack;
    NSNumber *c2 = [[NSNumber alloc] initWithInteger:(*counter).integerValue + 1];
    *counter = c2;
    vertex.dfsProperties.dfsTimestampFinished = *counter;
    vertex.dfsProperties.dfsFoundCounter = *counter;
    
    if (vertex != nil) {
        MTPair *pairVertices = [MTPair newPairWithFormer:vertex andLatter:*counter];
        [*listOfVertices add:pairVertices];
    }
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
