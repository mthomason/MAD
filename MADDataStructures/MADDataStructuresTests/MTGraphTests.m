//
//  MTGraphTests.m
//  MADDataStructuresTests
//
//  Created by Michael Thomason on 1/24/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>
#import "MTGraph.h"
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTLinkedList.h"

@interface MTGraphTests : XCTestCase
@end

@implementation MTGraphTests

#pragma mark - Initialization Tests

- (void)testInitWithNoVertices {
	MTGraph *graph = [[MTGraph alloc] init];
	XCTAssertEqual(graph.numberOfVertices, 0);
	XCTAssertEqual(graph.numberOfEdges, 0);
}

- (void)testInitWithVertices {
	MTVertex *v1 = [[MTVertex alloc] initWithID:0 andObject:@"A"];
	MTVertex *v2 = [[MTVertex alloc] initWithID:1 andObject:@"B"];
	MTGraph *graph = [[MTGraph alloc] initWithVertices:[NSSet setWithObjects:v1, v2, nil]];
	XCTAssertEqual(graph.numberOfVertices, 2);
}

#pragma mark - Vertex Management Tests

- (void)testAddVertex {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertex = [graph addVertexWithObject:@"A"];
	XCTAssertEqual(graph.numberOfVertices, 1);
	XCTAssertEqualObjects([graph vertexForObject:@"A"], vertex);
}

- (void)testRemoveVertex {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	[graph removeVertex:v1];
	XCTAssertEqual(graph.numberOfVertices, 0);
	XCTAssertNil([graph vertexForObject:@"A"]);
}

#pragma mark - Edge Management Tests

- (void)testAddEdgeBetweenExistingVertices {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	
	XCTAssertNotNil(edge);
	XCTAssertEqual(graph.numberOfEdges, 1);
	XCTAssertTrue([[graph allEdges] containsObject:edge]);
}

- (void)testAddDuplicateEdge {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	
	[graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	MTEdge *duplicateEdge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	
	XCTAssertNil(duplicateEdge);
	XCTAssertEqual(graph.numberOfEdges, 1);
}

- (void)testRemoveEdge {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	
	[graph removeEdge:edge];
	XCTAssertEqual(graph.numberOfEdges, 0);
}

#pragma mark - Graph Algorithm Tests

- (void)testBreadthFirstSearch {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:a destination:c object:nil andWeight:nil];
	
	NSArray *bfsResult = [graph breadthFirstSearch:a];
	NSArray *expectedOrder = @[a, b, c];
	XCTAssertEqualObjects(bfsResult, expectedOrder);
}

- (void)testDepthFirstSearch {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];
	
	MTLinkedList *dfsResult = [graph depthFirstSearch:a];
	NSArray *resultArray = [dfsResult toArray];
	XCTAssertEqual(resultArray.count, 3);
	XCTAssertEqualObjects(resultArray[0], a);
}

- (void)testTopologicalSortDAG {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];
	
	NSError *error;
	BOOL isDAG;
	MTLinkedList *result = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	
	XCTAssertTrue(isDAG);
	XCTAssertNil(error);
	XCTAssertEqual([result count], 3);
}

- (void)testTopologicalSortWithCycle {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];
	[graph addEdgeWithOrigin:c destination:a object:nil andWeight:nil];
	
	NSError *error;
	BOOL isDAG;
	MTLinkedList *result = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	
	XCTAssertFalse(isDAG);
	XCTAssertEqual([result count], 3);
}

#pragma mark - Edge Cases

- (void)testEmptyGraphOperations {
	MTGraph *graph = [[MTGraph alloc] init];
	
	XCTAssertEqual([graph numberOfVertices], 0);
	XCTAssertEqual([graph numberOfEdges], 0);
	XCTAssertNil([graph vertexForObject:@"Nonexistent"]);
	
	NSError *error;
	BOOL isDAG;
	MTLinkedList *emptySort = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	
	XCTAssertTrue(isDAG);
	XCTAssertEqual([emptySort count], 0);
}

@end
