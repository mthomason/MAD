//
//  MTVertex.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTVertex.h"
#import "MTEdge.h"

@interface MTVertex()

@property (nonatomic, retain) NSMutableArray *edges;     // MARK: The edges this node has
@property (nonatomic, retain) NSNumber *uniqueIdForStructure;

@end

@implementation MTVertex

- (void)dealloc {
    [_uniqueIdForStructure release];
    [_dfsTimestampDiscovered release];
    [_dfsTimestampFinished release];
    [_dfsFoundCounter release];
    [_dfsPredecessor release];
    [_dfsDistance release];
    [_bfsPredecessor release];
    [_bfsDistance release];
    [_edges release];
    [super dealloc];
}

- (id)init {
    return [self initWithID:0];
}

- (id)initWithID:(NSUInteger)idnumber {
    return [self initWithID:idnumber andObject:nil];
}

- (id)initWithID:(NSUInteger)idnumber andObject:(id)object {
    self = [super init];
    if (self) {
        
        NSNumber *number = [[NSNumber alloc] initWithInteger:idnumber];
        [self setUniqueIdForStructure:number];
        [number release];

        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self setEdges:array];
        [array release];
        
        id obj = [object retain];
        [self setObject: obj];
        [obj release];

    }
    return self;
}

- (NSUInteger)numberOfIncidentEdges {
    return [[self edges] count];
}

- (NSArray *)incidentEdges {
    NSArray *results;
    @synchronized(self) {
        results = [[[self edges] retain] autorelease];
    }
    return results;
}

- (void)addEdge:(MTEdge *)edge {
    if ([self edges]) {
        [[self edges] addObject:edge];
    } else {
        NSMutableArray *arrayEmpty = [[NSMutableArray alloc] initWithObjects:edge, nil];
        [self setEdges:arrayEmpty];
        [arrayEmpty release];
    }
}

- (BOOL)isAdjacentToVertex:(MTVertex *)vertex {
    BOOL result = NO;
    for (MTEdge *edge in [self edges]) {
        if ([[edge destination] isEqual:vertex]) {
            result = YES;
        }
    }
    return result;
}

- (void)removeEdge:(MTEdge *)edge {
    [[self edges] removeObject: edge];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if (self == sender) {
        result = YES;
    } else {
        MTVertex *v = sender;
        result = [[self uniqueIdForStructure] isEqualToNumber:[v uniqueIdForStructure]];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSString *humanReadableVector;
    if ([[self object] respondsToSelector:@selector(toStringHumanReadable)]) {
        humanReadableVector = [[self object] toStringHumanReadable];
    } else {
        humanReadableVector = [self toStringDebug];
    }
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"(%@)", humanReadableVector];
    for (MTEdge *edge in [self edges]) {
        [result appendString:@"->"];
        MTVertex *destination = [edge destination];
        [result appendString:[[destination object] toStringHumanReadable]];
    }
    return [result autorelease];
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"(%@)", self];
    for (MTEdge *edge in [self edges]) {
        [result appendString:@"\tEdge->"];
        [result appendString:[edge toStringDebug]];
    }
    return [result autorelease];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end