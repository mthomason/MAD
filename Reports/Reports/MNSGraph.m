//
//  MNSGraph.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSGraph.h"

@implementation MNSGraph

@synthesize vertices = _vertices;

- (void)dealloc {
    [_vertices release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSSet *set = [[NSSet alloc] init];
        [self setVertices: set];
        [set release];
    }
    return self;
}

- (id)initWithVertices:(NSSet *)vertices {
    self = [super init];
    if (self) {
        NSSet *set = [[NSSet alloc] initWithSet: vertices];
        [self setVertices: set];
        [set release];
    }
    return self;
}

@end