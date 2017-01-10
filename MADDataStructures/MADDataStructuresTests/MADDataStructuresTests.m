//
//  MADDataStructuresTests.m
//  MADDataStructuresTests
//
//  Created by Michael Thomason on 9/16/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTGraph.h"
#import "MTVertex.h"
#import "MADMapStrings.h"

@interface MADDataStructuresTests : XCTestCase

@end

@implementation MADDataStructuresTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMapStrings {
    
    NSString *ttt;
    @autoreleasepool {
        MADMapStrings *map = [[MADMapStrings alloc] init];
        [map setObject:@"Three" toKey:3];
        [map setObject:@"Two Hundred" toKey:200];
        
        @autoreleasepool {
            ttt = [NSString stringWithFormat:@"%s", "Three hundred thirty three"];
            [map setObject:ttt toKey:333];
        }
        
        @autoreleasepool {
            ttt = [NSString stringWithFormat:@"%s", "Thirty"];
            [map setObject:ttt toKey:30];
            ttt = nil;
        }

        [map setObject:@"Thirty" toKey:30];
        [map setObject:@"Forty-Seven" toKey:47];

        @autoreleasepool {
            ttt = [NSString stringWithFormat:@"%s", "Three hundred thirty three again"];
            [map setObject:ttt toKey:333];
        }

        [map setObject:@"Eighty-Four" toKey:84];
        [map setObject:@"Four" toKey:4];
        [map setObject:nil toKey:48];
        [map setObject:nil toKey:200];
        [map setObject:nil toKey:3];
        [map setObject:nil toKey:47];

        NSString *string = [map objectAtIndex:333];
        NSLog(@"Result: %@", string);
    }
    
    
    NSLog(@"Test");
    NSLog(@"Test");
    
    //MTLinkedList *dfsResultsU = [graph depthFirstSearch:vertexU];
    
}

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
    
}

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
    
    //NSLog(@"%@", [graph toStringHumanReadable]);
    
    NSError *error = nil;
    BOOL isDirectedAcyclicGraph;
    MTLinkedList *topologicalSort = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
    
    //NSLog(@"%@", [topologicalSort toStringHumanReadable]);
    XCTAssertNotNil(topologicalSort, @"Topological sort results are nil. Error returned is \"%@\"", [error localizedDescription]);
    XCTAssertNil(error, @"Topological sort showed error: %@", [error localizedDescription]);
}

@end
