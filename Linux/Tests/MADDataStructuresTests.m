//
//  MADDataStructuresTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MADDataStructuresTests.m: the graph's
//  full round trip -- vertices, edges, removal, breadth-first search and the
//  topological sort over the two classic examples.  The Xcode file's
//  setUp/tearDown property is a fresh graph per test here.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTEdge.h>
#import <MADDataStructures/MTLinkedList.h>

static void testGraphInitialization(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MAD_PASS(graph != nil, "graph initializes");
	MAD_PASS([graph numberOfVertices] == 0, "no vertices upon initialization");
	MAD_PASS([graph numberOfEdges] == 0, "no edges upon initialization");
}

static void testAddVertex(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertex = [graph addVertexWithObject:@"TestVertex"];
	MAD_PASS(vertex != nil, "the added vertex is not nil");
	MAD_PASS([graph numberOfVertices] == 1, "one vertex after adding");
	MAD_PASS_EQUAL(vertex.object, @"TestVertex", "the vertex holds the input object");
}

static void testAddEdge(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertexA = [graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(10)];
	MAD_PASS(edge != nil, "the added edge is not nil");
	MAD_PASS_EQUAL(edge.origin, vertexA, "the edge origin is the source vertex");
	MAD_PASS_EQUAL(edge.destination, vertexB, "the edge destination is the target vertex");
	MAD_PASS([graph numberOfEdges] == 1, "one edge after adding");
}

static void testRemoveVertex(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertex = [graph addVertexWithObject:@"ToRemove"];
	[graph removeVertex:vertex];
	MAD_PASS([graph numberOfVertices] == 0, "no vertices after removal");
}

static void testRemoveEdge(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertexA = [graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(10)];
	[graph removeEdge:edge];
	MAD_PASS([graph numberOfEdges] == 0, "no edges after removal");
}

static void testBreadthFirstSearch(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertexA = [graph addVertexWithObject:@"A"];
	MTVertex *vertexB = [graph addVertexWithObject:@"B"];
	MTVertex *vertexC = [graph addVertexWithObject:@"C"];
	[graph addEdgeWithOrigin:vertexA destination:vertexB object:@"A->B" andWeight:@(1)];
	[graph addEdgeWithOrigin:vertexB destination:vertexC object:@"B->C" andWeight:@(1)];

	NSArray *bfsResult = [graph breadthFirstSearch:vertexA];
	MAD_PASS(bfsResult.count == 3, "BFS visits all vertices");
	MAD_PASS_EQUAL(bfsResult[0], vertexA, "the root is first");
	MAD_PASS_EQUAL(bfsResult[1], vertexB, "the second vertex follows BFS order");
	MAD_PASS_EQUAL(bfsResult[2], vertexC, "the third vertex follows BFS order");
}

// The original file's DFS and topological-sort tests are kept as smoke tests:
// both walk a graph and report a result; the shape of that result is pinned in
// MTGraphTests.
static void testDepthFirstSearchSmoke(void) {
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

	MTLinkedList *dfsResults = [graph depthFirstSearch:vertexU];
	MAD_PASS(dfsResults != nil, "DFS returns a list");
}

static void testTopologicalSort(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertexUndershorts = [graph addVertexWithObject:@"Undershorts"];
	MTVertex *vertexSocks = [graph addVertexWithObject:@"Socks"];
	MTVertex *vertexPants = [graph addVertexWithObject:@"Pants"];
	MTVertex *vertexShoes = [graph addVertexWithObject:@"Shoes"];
	[graph addVertexWithObject:@"Watch"];
	MTVertex *vertexShirt = [graph addVertexWithObject:@"Shirt"];
	MTVertex *vertexBelt = [graph addVertexWithObject:@"Belt"];
	MTVertex *vertexTie = [graph addVertexWithObject:@"Tie"];
	MTVertex *vertexJacket = [graph addVertexWithObject:@"Jacket"];

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
	BOOL isDirectedAcyclicGraph = NO;
	MTLinkedList *topologicalSort = [graph topologicalSortWithError:&error
											 isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
	MAD_PASS(topologicalSort != nil, "the topological sort returns a list");
	MAD_PASS(error == nil, "no error from the topological sort");
}

MAD_TEST_MAIN("MADDataStructuresTests",
	MAD_TEST(testGraphInitialization),
	MAD_TEST(testAddVertex),
	MAD_TEST(testAddEdge),
	MAD_TEST(testRemoveVertex),
	MAD_TEST(testRemoveEdge),
	MAD_TEST(testBreadthFirstSearch),
	MAD_TEST(testDepthFirstSearchSmoke),
	MAD_TEST(testTopologicalSort));
