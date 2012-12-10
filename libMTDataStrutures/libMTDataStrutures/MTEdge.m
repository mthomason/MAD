//
//  MTEdge.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTEdge.h"

@interface MTEdge ()

@property(nonatomic, retain) id object;
@property(nonatomic, retain) NSMutableArray *vertices;
@property(nonatomic, retain) NSNumber *weight;
@property(assign, readwrite) BOOL isDirected;

@end

@implementation MTEdge

- (id)initWithOrigin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2 {
    return [self initWithOrigin:vertex1 destination:vertex2 andObject:nil];
}

- (id)initWithOrigin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id)object {
    return [self initWithOrigin:vertex1 destination:vertex2 object:nil andWeight:@(1)];
}

- (id)initWithOrigin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 object:(id)object andWeight:(NSNumber *)weight {
    self = [super init];
    if (self) {

        [self setIsDirected:YES];

        NSMutableArray *mutableVertices = [[NSMutableArray alloc] initWithCapacity:2];
        [mutableVertices addObject: vertex1];
        [mutableVertices addObject: vertex2];
        [self setVertices:mutableVertices];
        [mutableVertices release];
        
        [self setObject:object];
        [self setWeight:weight];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL result;
    if (self == object) {
        result = YES;
    } else {
        result = ([self isDirected] == [object isDirected] &&
                  [[self weight] isEqual:[object weight]] &&
                  [[self object] isEqual:[object object]] &&
                  [[self vertices] isEqualToArray:[object vertices]]);
    }
    return result;
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    NSUInteger yesPrime = 1231;
    NSUInteger noPrime = 1237;
    result = prime * result + [[self object] hash];
    for (MTVertex *vertex in [self vertices]) {
        result = prime * result + [vertex hash];
    }
    result = prime * result + [[self weight] hash];
    result = prime * result + [self isDirected] ? yesPrime : noPrime;
    return result;
}

- (void)dealloc {
    [_object release];
    [_vertices release];
    [_weight release];
    [super dealloc];
}

@end