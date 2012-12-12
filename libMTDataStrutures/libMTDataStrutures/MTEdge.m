//
//  MTEdge.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTEdge.h"
#import "MTPair.h"

@interface MTEdge ()

@property(retain) MTPair *vertices;
@property(retain) NSNumber *weight;
@property(readwrite, assign) BOOL isDirected;

@end

@implementation MTEdge

- (MTVertex *)origin {
    return [[self vertices] former];
}

- (MTVertex *)destination {
    return [[self vertices] latter];
}

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
        
        MTPair *pair = [[MTPair alloc] initWithFormer:vertex1 andLatter:vertex2];
        [self setVertices:pair];
        [pair release];
        
        id obj = [object retain];
        [self setObject: obj];
        [obj release];
        
        NSNumber *w = [weight retain];
        [self setWeight:w];
        [w release];

    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return (self == object) ? YES :  ([self isDirected] == [object isDirected] &&
                                      [[self weight] isEqual:[object weight]] &&
                                      [[self object] isEqual:[object object]] &&
                                      [[[self vertices] former] isEqual:[[object vertices] former]] &&
                                      [[[self vertices] latter] isEqual:[[object vertices] latter]]);
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    NSUInteger yesPrime = 1231;
    NSUInteger noPrime = 1237;
    result = prime * result + [[self object] hash];
    result = prime * result + [[[self vertices] former] hash];
    result = prime * result + [[[self vertices] latter] hash];
    result = prime * result + [[self weight] hash];
    result = prime * result + [self isDirected] ? yesPrime : noPrime;
    return result;
}

- (void)dealloc {
    [_vertices release];
    [_weight release];
    [super dealloc];
}

@end