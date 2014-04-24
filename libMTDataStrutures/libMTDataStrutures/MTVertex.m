//
//  MTVertex.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTVertex.h"
#import "MTEdge.h"

@interface MTVertex()

@property (nonatomic, strong) NSMutableArray *edges;     // MARK: The edges this node has
@property (nonatomic, strong) NSNumber *uniqueIdForStructure;

@end

@implementation MTVertex

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

        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self setEdges:array];
        
        [self setObject: object];

    }
    return self;
}

- (NSUInteger)numberOfIncidentEdges {
    return [[self edges] count];
}

- (NSArray *)incidentEdges {
    NSArray *results;
    @synchronized(self) {
        results = [self edges];
    }
    return results;
}

- (void)addEdge:(MTEdge *)edge {
    if ([self edges]) {
        [[self edges] addObject:edge];
    } else {
        NSMutableArray *arrayEmpty = [[NSMutableArray alloc] initWithObjects:edge, nil];
        [self setEdges:arrayEmpty];
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
        id destinationObject = [destination object];
        NSString *desc = @"";
        if ([destinationObject respondsToSelector:@selector(toStringHumanReadable)]) {
            desc = [destinationObject toStringHumanReadable];
        } else {
            desc = [NSString stringWithFormat:@"%@", destinationObject];
        }
        [result appendString:desc];
    }
    return result;
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"(%@)", self];
    for (MTEdge *edge in [self edges]) {
        [result appendString:@"\tEdge->"];
        [result appendString:[edge toStringDebug]];
    }
    return result;
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end
