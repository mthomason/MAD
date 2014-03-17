//
//  MTDataStructuresTesting.m
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDataStructuresTest.h"

@implementation MTDataStructuresTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDepthFirstSearch {
    
    MTGraph *graph = [[MTGraph alloc] init];
    
    MTVertex *vertexU = [[graph addVertexWithObject:@"U"] retain];
    MTVertex *vertexV = [[graph addVertexWithObject:@"V"] retain];
    MTVertex *vertexW = [[graph addVertexWithObject:@"W"] retain];
    MTVertex *vertexX = [[graph addVertexWithObject:@"X"] retain];
    MTVertex *vertexY = [[graph addVertexWithObject:@"Y"] retain];
    MTVertex *vertexZ = [[graph addVertexWithObject:@"Z"] retain];
    
    [graph addEdgeWithOrigin:vertexX destination:vertexV object:@"X->V" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexZ destination:vertexZ object:@"Z->Z" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexW destination:vertexY object:@"W->Y" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexW destination:vertexZ object:@"W->Z" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexU destination:vertexV object:@"U->V" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexV destination:vertexY object:@"V->Y" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexY destination:vertexX object:@"Y->X" andWeight:@(1)];
    [graph addEdgeWithOrigin:vertexU destination:vertexX object:@"U->X" andWeight:@(1)];
    
    //NSLog(@"%@", [graph toStringHumanReadable]);

    MTLinkedList *dfsResultsU = [[graph depthFirstSearch:vertexU] retain];
    //NSLog(@"U:\t%@", [dfsResultsU toStringHumanReadable]);

    [dfsResultsU release];
    
    [graph release];

    [vertexZ release];
    [vertexY release];
    [vertexX release];
    [vertexW release];
    [vertexV release];
    [vertexU release];

}

- (void)testTopologicalSort {
    
    MTGraph *graph = [[MTGraph alloc] init];
    
    MTVertex *vertexUndershorts     = [[graph addVertexWithObject:@"Undershorts"] retain];
    MTVertex *vertexSocks           = [[graph addVertexWithObject:@"Socks"] retain];
    MTVertex *vertexPants           = [[graph addVertexWithObject:@"Pants"] retain];
    MTVertex *vertexShoes           = [[graph addVertexWithObject:@"Shoes"] retain];
    MTVertex *vertexWatch           = [[graph addVertexWithObject:@"Watch"] retain];
    MTVertex *vertexShirt           = [[graph addVertexWithObject:@"Shirt"] retain];
    MTVertex *vertexBelt            = [[graph addVertexWithObject:@"Belt"] retain];
    MTVertex *vertexTie             = [[graph addVertexWithObject:@"Tie"] retain];
    MTVertex *vertexJacket          = [[graph addVertexWithObject:@"Jacket"] retain];
    
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
    MTLinkedList *topologicalSort = [[graph topologicalSortWithError:&error] retain];
    
    //NSLog(@"%@", [topologicalSort toStringHumanReadable]);
    
    [topologicalSort release];
    [graph release];
    
    [vertexJacket release];
    [vertexTie release];
    [vertexBelt release];
    [vertexShirt release];
    [vertexWatch release];
    [vertexShoes release];
    [vertexPants release];
    [vertexSocks release];
    [vertexUndershorts release];

    STAssertNil(error, [error localizedDescription]);
}


@end