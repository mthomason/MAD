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

- (void)dealloc {
    [_vertices release];
    [_weight release];
    [super dealloc];
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

- (MTVertex *)origin {
    return [[self vertices] former];
}

- (MTVertex *)destination {
    return [[self vertices] latter];
}

- (BOOL)isEqualTo:(id)object {
    BOOL objectComparson;
    if ([object conformsToProtocol:@protocol(MTProtocolCompare)]) {
        objectComparson = [[self object] isEqualTo:[object object]];
    } else {
        objectComparson = [[self object] isEqual:[object object]];
    }
    return (self == object) ? YES :  (objectComparson &&
                                      [self isDirected] == [object isDirected] &&
                                      [[self weight] compare:[object weight]] &&
                                      [[[self vertices] former] isEqualTo:[[object vertices] former]] &&
                                      [[[self vertices] latter] isEqualTo:[[object vertices] latter]]);
}

// MARK: MTProtocolLog

- (NSString *)humanReadableObjectIdentifier {
    return [NSString stringWithFormat:@"->%@", [[self destination] humanReadableObjectIdentifier]];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, [[self origin] humanReadableObjectIdentifier], [[self destination] humanReadableObjectIdentifier]];
}

- (NSString *)toStringForDebugging {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, [self origin], [self destination]];
}

@end