//
//  MTVertex.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTVertex.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import "MTEdge.h"
#import "MADAlgorithmElementProperties.h"
#import "MADBfsProperties.h"
#import "MADDfsProperties.h"
#import "MADSortProperties.h"

@interface MTVertex()

    @property (nonatomic, strong) NSMutableArray <MTEdge *> *edges;     // MARK: The edges this node has
    @property (nonatomic, assign, readwrite) NSUInteger uniqueIdForStructure;

    @property (nonatomic, strong, readwrite) MADAlgorithmElementProperties *properties;
    @property (nonatomic, strong, readwrite) MADBfsProperties *bfsProperties;
    @property (nonatomic, strong, readwrite) MADDfsProperties *dfsProperties;
    @property (nonatomic, strong, readwrite) MADSortProperties *sortProperties;

@end

@implementation MTVertex

/*- (id)copyWithZone:(nullable NSZone *)zone {
    
    MTVertex *copy = [[[self class] allocWithZone: zone] initWithID:_uniqueIdForStructure
                                                          andObject:self.object];
    NSMutableArray *newEdges = [[NSMutableArray alloc] initWithCapacity:_edges.count];
    copy.edges = newEdges;

    MTEdge *edge, *edgeCopy;
    for (edge in _edges) {
        edgeCopy = [edge copyWithZone:zone];
        [copy.edges addObject:edgeCopy];
    }
    copy.bfsProperties = [_bfsProperties copyWithZone:zone];
    copy.dfsProperties = [_dfsProperties copyWithZone:zone];
    copy.sortProperties = [_sortProperties copyWithZone:zone];
    copy.properties = [_properties copyWithZone:zone];
    copy.uniqueIdForStructure = _uniqueIdForStructure;
    
    return copy;
}*/

- (instancetype)init {
    return [self initWithID:0];
}

- (instancetype)initWithID:(NSUInteger)idnumber {
    return [self initWithID:idnumber andObject:nil];
}

- (instancetype)initWithID:(NSUInteger)idnumber andObject:(id <NSCopying>)object {
    if (self = [super init]) {
        
        _uniqueIdForStructure = idnumber;
        _object = [object copyWithZone:nil];

        NSMutableArray *array = [[NSMutableArray alloc] init];
        self.edges = array;

    }
    return self;
}

- (NSUInteger)numberOfIncidentEdges { return self.edges.count; }

- (NSArray <MTEdge *> *)incidentEdges {
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
        self.edges = arrayEmpty;
    }
}

- (BOOL)isAdjacentToVertex:(MTVertex *)vertex {
    BOOL result = NO;
    NSArray *edges = self.edges;
    for (MTEdge *edge in edges) {
        if ([edge.destination isEqual:vertex]) {
            result = YES;
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
        MTVertex *destination = edge.destination;
        id destinationObject = destination.object;
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

- (MADAlgorithmElementProperties *)properties {
    if (!_properties) {
        MADAlgorithmElementProperties *properties;
        properties = [[MADAlgorithmElementProperties alloc] init];
        _properties = properties;
    }
    return _properties;
}

- (MADBfsProperties *)bfsProperties {
    if (!_bfsProperties) {
        MADBfsProperties *bfsProperties;
        bfsProperties = [[MADBfsProperties alloc] init];
        _bfsProperties = bfsProperties;
    }
    return _bfsProperties;
}

- (MADDfsProperties *)dfsProperties {
    if (!_dfsProperties) {
        MADDfsProperties *dfsProperties;
        dfsProperties = [[MADDfsProperties alloc] init];
        _dfsProperties = dfsProperties;
    }
    return _dfsProperties;
}

- (MADSortProperties *)sortProperties {
    if (!_sortProperties) {
        MADSortProperties *sortProperties;
        sortProperties = [[MADSortProperties alloc] init];
        _sortProperties = sortProperties;
    }
    return _sortProperties;
}

@end
