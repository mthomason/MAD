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
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import "MTEdge.h"
#import "MADAlgorithmElementProperties.h"

@interface MTVertex()

@property (nonatomic, strong) NSMutableArray <MTEdge *> *edges;     // MARK: The edges this node has
@property (nonatomic, assign, readwrite) NSUInteger uniqueIdForStructure;

@end

@implementation MTVertex

/*- (id)copyWithZone:(nullable NSZone *)zone {
    MTVertex *copy = [[[self class] alloc] initWithID:self.uniqueIdForStructure andObject:self.object];
    NSArray *edges = self.edges;
    for (MTEdge *edge in edges) {
        MTEdge *edgeCopy = [edge copyWithZone:zone];
        [copy.edges addObject:edgeCopy];
    }
    id properties = [self.properties copyWithZone:zone];
    copy.properties = properties;
    return copy;
}*/

- (instancetype)init {
    return [self initWithID:0];
}

- (instancetype)initWithID:(NSUInteger)idnumber {
    return [self initWithID:idnumber andObject:nil];
}

- (instancetype)initWithID:(NSUInteger)idnumber andObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        self.uniqueIdForStructure = idnumber;

        NSMutableArray *array = [[NSMutableArray alloc] init];
        self.edges = array;

    }
    return self;
}

- (NSUInteger)numberOfIncidentEdges { return self.edges.count; }

- (NSArray *)incidentEdges {
    NSArray *results;
    @synchronized(self) {
        results = self.edges;
    }
    return results;
}

- (void)addEdge:(MTEdge *)edge {
    if (self.edges) {
        [self.edges addObject:edge];
    } else {
        NSMutableArray *arrayEmpty = [[NSMutableArray alloc] initWithObjects:edge, nil];
        [self setEdges:arrayEmpty];
    }
}

- (bool)isAdjacentToVertex:(MTVertex *)vertex {
    bool result = false;
    NSArray *edges = self.edges;
    for (MTEdge *edge in edges) {
        if ([[edge destination] isEqual:vertex]) {
            result = true;
        }
    }
    return result;
}

- (void)removeEdge:(MTEdge *)edge {
    [self.edges removeObject: edge];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    if (self == sender) {
        return YES;
    } else {
        return [sender isKindOfClass:[MTVertex class]] ?
            self.uniqueIdForStructure == ((MTVertex *)sender).uniqueIdForStructure : NO;
    }
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSString *humanReadableVector;
    if ([self.object respondsToSelector:@selector(toStringHumanReadable)]) {
        humanReadableVector = [self.object toStringHumanReadable];
    } else {
        humanReadableVector = [self toStringDebug];
    }
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"(%@)", humanReadableVector];
    for (MTEdge *edge in self.edges) {
        [result appendString:@"->"];
        MTVertex *destination = [edge destination];
        id destinationObject = [destination object];
        NSString *desc = [destinationObject respondsToSelector:@selector(toStringHumanReadable)] ?
                            [destinationObject toStringHumanReadable] :
                            [NSString stringWithFormat:@"%@", destinationObject];
        [result appendString:desc];
    }
    return result;
}

- (NSString *)toString {
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"(%@)", self];
    for (MTEdge *edge in self.edges) {
        [result appendString:@"\tEdge->"];
        [result appendString:[edge toStringDebug]];
    }
    return result;
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (MADBfsProperties *)bfsProperties {
    return (MADBfsProperties *)self.properties;
}

- (MADDfsProperties *)dfsProperties {
    return (MADDfsProperties *)self.properties;
}

- (MADSortProperties *)sortProperties {
    return (MADSortProperties *)self.properties;
}

@end
