//
//  MTGraphTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MTGraphTests.m: vertex and edge
//  management, breadth-first and depth-first search, topological sort and the
//  empty-graph edge cases.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTEdge.h>
#import <MADDataStructures/MTLinkedList.h>

static void testInitWithNoVertices(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MAD_PASS(graph.numberOfVertices == 0, "a new graph has no vertices");
	MAD_PASS(graph.numberOfEdges == 0, "a new graph has no edges");
}

static void testInitWithVertices(void) {
	MTVertex *v1 = [[MTVertex alloc] initWithID:0 andObject:@"A"];
	MTVertex *v2 = [[MTVertex alloc] initWithID:1 andObject:@"B"];
	MTGraph *graph = [[MTGraph alloc] initWithVertices:[NSSet setWithObjects:v1, v2, nil]];
	MAD_PASS(graph.numberOfVertices == 2, "the graph holds the two vertices it was given");
}

static void testAddVertex(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *vertex = [graph addVertexWithObject:@"A"];
	MAD_PASS(graph.numberOfVertices == 1, "the graph has one vertex after adding");
	MAD_PASS_EQUAL([graph vertexForObject:@"A"], vertex, "the object finds its vertex");
}

static void testRemoveVertex(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	[graph removeVertex:v1];
	MAD_PASS(graph.numberOfVertices == 0, "the graph has no vertices after removal");
	MAD_PASS([graph vertexForObject:@"A"] == nil, "a removed vertex is not found");
}

static void testAddEdgeBetweenExistingVertices(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	MAD_PASS(edge != nil, "the edge is created");
	MAD_PASS(graph.numberOfEdges == 1, "the graph has one edge after adding");
	MAD_PASS([[graph allEdges] containsObject:edge], "the edge is among the graph's edges");
}

static void testAddDuplicateEdge(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	[graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	MTEdge *duplicateEdge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	MAD_PASS(duplicateEdge == nil, "a duplicate edge is refused");
	MAD_PASS(graph.numberOfEdges == 1, "the duplicate left the edge count alone");
}

static void testRemoveEdge(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *v1 = [graph addVertexWithObject:@"A"];
	MTVertex *v2 = [graph addVertexWithObject:@"B"];
	MTEdge *edge = [graph addEdgeWithOrigin:v1 destination:v2 object:nil andWeight:nil];
	[graph removeEdge:edge];
	MAD_PASS(graph.numberOfEdges == 0, "the graph has no edges after removal");
}

static void testBreadthFirstSearch(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:a destination:c object:nil andWeight:nil];

	NSArray *bfsResult = [graph breadthFirstSearch:a];
	MAD_PASS_EQUAL(bfsResult, (@[a, b, c]), "breadth-first search visits in the expected order");
}

static void testDepthFirstSearch(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];

	MTLinkedList *dfsResult = [graph depthFirstSearch:a];
	NSArray *resultArray = [dfsResult toArray];
	MAD_PASS(resultArray.count == 3, "depth-first search visits every vertex");
	MAD_PASS_EQUAL(resultArray[0], a, "depth-first search starts at the root");
}

static void testTopologicalSortDAG(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];

	NSError *error = nil;
	BOOL isDAG = NO;
	MTLinkedList *result = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	MAD_PASS(isDAG, "a chain is a DAG");
	MAD_PASS(error == nil, "no error from the DAG sort");
	MAD_PASS([result count] == 3, "the sort returns every vertex");
}

static void testTopologicalSortWithCycle(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MTVertex *a = [graph addVertexWithObject:@"A"];
	MTVertex *b = [graph addVertexWithObject:@"B"];
	MTVertex *c = [graph addVertexWithObject:@"C"];
	[graph addEdgeWithOrigin:a destination:b object:nil andWeight:nil];
	[graph addEdgeWithOrigin:b destination:c object:nil andWeight:nil];
	[graph addEdgeWithOrigin:c destination:a object:nil andWeight:nil];

	NSError *error = nil;
	BOOL isDAG = YES;
	MTLinkedList *result = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	MAD_PASS(!isDAG, "a cycle is not a DAG");
	MAD_PASS([result count] == 3, "the sort still returns every vertex");
}

static void testEmptyGraphOperations(void) {
	MTGraph *graph = [[MTGraph alloc] init];
	MAD_PASS([graph numberOfVertices] == 0, "an empty graph has no vertices");
	MAD_PASS([graph numberOfEdges] == 0, "an empty graph has no edges");
	MAD_PASS([graph vertexForObject:@"Nonexistent"] == nil, "a nonexistent object is not found");

	NSError *error = nil;
	BOOL isDAG = NO;
	MTLinkedList *emptySort = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDAG];
	MAD_PASS(isDAG, "an empty graph is a DAG");
	MAD_PASS([emptySort count] == 0, "the empty sort returns nothing");
}

MAD_TEST_MAIN("MTGraphTests",
	MAD_TEST(testInitWithNoVertices),
	MAD_TEST(testInitWithVertices),
	MAD_TEST(testAddVertex),
	MAD_TEST(testRemoveVertex),
	MAD_TEST(testAddEdgeBetweenExistingVertices),
	MAD_TEST(testAddDuplicateEdge),
	MAD_TEST(testRemoveEdge),
	MAD_TEST(testBreadthFirstSearch),
	MAD_TEST(testDepthFirstSearch),
	MAD_TEST(testTopologicalSortDAG),
	MAD_TEST(testTopologicalSortWithCycle),
	MAD_TEST(testEmptyGraphOperations));
