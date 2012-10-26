//
//  MNSVertex.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSVertex.h"

@implementation MNSVertex

@synthesize container = _container;
@synthesize linkedEdges = _linkedEdges;

- (void)dealloc {
    [_container release];
    [_linkedEdges release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSObject *obj = [[NSObject alloc] init];
        [self setContainer: obj];
        [obj release];
        NSSet *set = [[NSSet alloc] init];
        [self setLinkedEdges: set];
        [set release];
    }
    return self;
}

- (id)initWithObject:(id)object withEdges:(NSSet *)edges {
    self = [super init];
    if (self) {
        [self setContainer: [[object retain] autorelease]];
        NSSet *set = [[NSSet alloc] initWithSet: edges];
        [self setLinkedEdges: set];
        [set release];

    }
    return self;
}

@end