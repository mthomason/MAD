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

// MARK: NSObject Overrides

- (void)dealloc {
    [_vertices release];
    [super dealloc];
}

- (id)init {
    return [self initWithVertices:[NSSet set]];
}

// MARK: Factory

- (id)initWithVertices:(NSSet *)verticesSet {
    self = [super init];
    if (self) {
        NSMutableArray *vertices = [[NSMutableArray alloc] initWithArray: [verticesSet allObjects]];
        [self setVertices: vertices];
        [vertices release];
    }
    return self;
}

// MARK: Members

- (void)insertVertex:(MTVertex *)newVertex {
    [[self vertices] addObject:newVertex];
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
        if ([edge isEqual:existingEdge]) {
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
- (MTGraph *)breadthFirstSearch:(MTVertex *)vertexSource {
    
    MTQueue *greyVertices = [[MTQueue alloc] init];
    MTGraph *breadthFirstTree = [[MTGraph alloc] init];
    for (MTVertex *vertex in [self vertices]) {
        [vertex setBfsVertexColor:MTColorWhite];
    }
    [vertexSource setBfsDistance:@(0)];
    [vertexSource setBfsVertexColor:MTColorGray];
    [vertexSource setBfsPredecessor:nil];
    
    [greyVertices enqueue:vertexSource];

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
        [breadthFirstTree insertVertex:u];
    } while ([greyVertices count] > 0);
    
    [greyVertices release];
    
    return [breadthFirstTree autorelease];
}

// MARK: MTProtocolLog

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