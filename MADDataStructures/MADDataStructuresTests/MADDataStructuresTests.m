//
//  MADDataStructuresTests.m
//  MADDataStructuresTests
//
//  Created by Michael Thomason on 9/16/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>
#import "MTGraph.h"
#import "MTVertex.h"
#import "MTEdge.h"
#import "MTLinkedList.h"

@interface MADDataStructuresTests : XCTestCase
	@property (nonatomic, strong) MTGraph *graph;
@end

@implementation MADDataStructuresTests

- (void)setUp {
	[super setUp];
	self.graph = [[MTGraph alloc] init];
}

- (void)tearDown {
	self.graph = nil;
	[super tearDown];
}

- (void)testGraphInitialization {
	XCTAssertNotNil(self.graph, "Graph should not be nil after initialization.");
	XCTAssertEqual([self.graph numberOfVertices], 0, "Graph should have no vertices upon initialization.");
	XCTAssertEqual([self.graph numberOfEdges], 0, "Graph should have no edges upon initialization.");
}

- (void)testAddVertex {
	MTVertex *vertex = [self.graph addVertexWithObject:@"TestVertex"];
	XCTAssertNotNil(vertex, "Added vertex should not be nil.");
	XCTAssertEqual([self.graph numberOfVertices], 1, "Graph should have one vertex after adding.");
	XCTAssertEqualObjects(vertex.object, @"TestVertex", "Vertex object should match the input object.");
}

- (void)testAddEdge {
	MTVertex *vertexA = [self.graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [self.graph addVertexWithObject:@"B"];

	MTEdge *edge = [self.graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(10)];
	XCTAssertNotNil(edge, "Added edge should not be nil.");
	XCTAssertEqualObjects(edge.origin, vertexA, "Edge origin should match the source vertex.");
	XCTAssertEqualObjects(edge.destination, vertexB, "Edge destination should match the target vertex.");
	XCTAssertEqual([self.graph numberOfEdges], 1, "Graph should have one edge after adding.");
}

- (void)testRemoveVertex {
	MTVertex *vertex = [self.graph addVertexWithObject:@"ToRemove"];
	[self.graph removeVertex:vertex];

	XCTAssertEqual([self.graph numberOfVertices], 0, "Graph should have no vertices after removal.");
}

- (void)testRemoveEdge {
	MTVertex *vertexA = [self.graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [self.graph addVertexWithObject:@"B"];
	MTEdge *edge = [self.graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(10)];

	[self.graph removeEdge:edge];
	XCTAssertEqual([self.graph numberOfEdges], 0, "Graph should have no edges after removal.");
}

- (void)testBreadthFirstSearch {
	MTVertex *vertexA = [self.graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [self.graph addVertexWithObject:@"B"];
	MTVertex *vertexC = [self.graph addVertexWithObject:@"C"];
	[self.graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(1)];
	[self.graph addEdgeWithOrigin:vertexB destination:vertexC object:@"B->C" andWeight:@(1)];

	NSArray *bfsResult = [self.graph breadthFirstSearch:vertexA];
	XCTAssertEqual(bfsResult.count, 3, "BFS should visit all vertices in the graph.");
	XCTAssertEqualObjects(bfsResult[0], vertexA, "First vertex should be the root.");
	XCTAssertEqualObjects(bfsResult[1], vertexB, "Second vertex should follow BFS order.");
	XCTAssertEqualObjects(bfsResult[2], vertexC, "Third vertex should follow BFS order.");
}

/*
	DFS isn't used in the program, so DFS results may be unexpected. It's currently returning
		MTPair values of the edges.  This may be unexpected, so it's not tested.  The MTPair
		contains metadata, and it's not stripped out of the results.  Consider it a speed hack
		for now.
*/
- (void)testDepthFirstSearch {
	
	MTGraph *graph = [[MTGraph alloc] init];
	
	MTVertex *vertexU = [graph addVertexWithObject:@"U"];
	MTVertex *vertexV = [graph addVertexWithObject:@"V"];
	MTVertex *vertexW = [graph addVertexWithObject:@"W"];
	MTVertex *vertexX = [graph addVertexWithObject:@"X"];
	MTVertex *vertexY = [graph addVertexWithObject:@"Y"];
	MTVertex *vertexZ = [graph addVertexWithObject:@"Z"];
	
	[graph addEdgeWithOrigin:vertexX destination:vertexV object:@"X->V" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexZ destination:vertexZ object:@"Z->Z" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexW destination:vertexY object:@"W->Y" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexW destination:vertexZ object:@"W->Z" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexU destination:vertexV object:@"U->V" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexV destination:vertexY object:@"V->Y" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexY destination:vertexX object:@"Y->X" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexU destination:vertexX object:@"U->X" andWeight:@(1)];
	
	MTLinkedList *dfsResultsU = [graph depthFirstSearch:vertexU];
	NSLog(@"%@", [dfsResultsU toArray]);
	
}

/*
	The `topologicalSortWithError: isDirectedAcyclicGraph:` returns an MTLinkedList of MTPair's.
		This extra metadata may be unexpected.  This function works well in the program, because
		its use accounts for this.  If this class is going to be used in other projects, the
		function may need to be rewritten to return results that would be expected by more
		generic use cases.  If you search this workspace for `isDirectedAcyclicGraph`, you will
		find how it's used.  These implementation details, though not perfectly orthogonal, work
		well for this program.  That's because the MTPar is used internally, and so that internal
		structure, and it's metadata is simply returned as a speed hack.
 */

- (void)testTopologicalSort {
	
	MTGraph *graph = [[MTGraph alloc] init];
	
	MTVertex *vertexUndershorts     = [graph addVertexWithObject:@"Undershorts"];
	MTVertex *vertexSocks           = [graph addVertexWithObject:@"Socks"];
	MTVertex *vertexPants           = [graph addVertexWithObject:@"Pants"];
	MTVertex *vertexShoes           = [graph addVertexWithObject:@"Shoes"];
	[graph addVertexWithObject:@"Watch"];
	MTVertex *vertexShirt           = [graph addVertexWithObject:@"Shirt"];
	MTVertex *vertexBelt            = [graph addVertexWithObject:@"Belt"];
	MTVertex *vertexTie             = [graph addVertexWithObject:@"Tie"];
	MTVertex *vertexJacket          = [graph addVertexWithObject:@"Jacket"];
	
	[graph addEdgeWithOrigin:vertexUndershorts destination:vertexShoes object:@"Undershorts->Shoes" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexUndershorts destination:vertexPants object:@"Undershorts->Pants" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexPants destination:vertexShoes object:@"Pants->Shoes" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexPants destination:vertexBelt object:@"Pants->Belt" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexBelt destination:vertexJacket object:@"Belt->Jacket" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexTie destination:vertexJacket object:@"Tie->Jacket" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexShirt destination:vertexBelt object:@"Shirt->Belt" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexShirt destination:vertexTie object:@"Shirt->Tie" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexSocks destination:vertexShoes object:@"Socks->Shoes" andWeight:@(1)];
	
	NSError *error = nil;
	BOOL isDirectedAcyclicGraph;
	MTLinkedList *topologicalSort = [graph topologicalSortWithError:&error
											 isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
	
	XCTAssertNotNil(topologicalSort, @"Topological sort results are nil. Error returned is \"%@\"", [error localizedDescription]);
	XCTAssertNil(error, @"Topological sort showed error: %@", [error localizedDescription]);
}

@end
