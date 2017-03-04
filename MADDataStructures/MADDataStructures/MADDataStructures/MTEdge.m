//
//  MTEdge.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTEdge.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import "MTPair.h"
#import "MTVertex.h"

@interface MTEdge ()

    @property (nonatomic, weak, readwrite) MTVertex *origin;
    @property (nonatomic, weak, readwrite) MTVertex *destination;

    @property (nonatomic, strong) NSNumber *weight;
    @property (nonatomic, readwrite, assign, getter=isDirected) BOOL directed;
    @property (nonatomic, strong) NSNumber *uniqueIdForStructure;

@end

@implementation MTEdge

- (id)copyWithZone:(nullable NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithUniqueID: self.uniqueIdForStructure
                                                           origin: self.origin
                                                      destination: self.destination
                                                           object: self.object
                                                        andWeight: self.weight];
    return copy;
}

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2 {
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 andObject:nil];
}

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id <NSCopying>)object {
    NSNumber *one = @(1);
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 object:nil andWeight:one];
}

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID
                          origin:(MTVertex *)vertex1
                     destination:(MTVertex *)vertex2
                          object:(id <NSCopying>)object
                       andWeight:(NSNumber *)weight {
    if (self = [super initWithObject:object]) {

        _directed = YES;
        
        self.origin = vertex1;
        self.destination = vertex2;

        self.weight = weight.copy;
        self.uniqueIdForStructure = uniqueID.copy;
    }
    return self;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if (self == sender) {
        result = YES;
    } else {
        result = [self.uniqueIdForStructure isEqualToNumber:((MTEdge *)sender).uniqueIdForStructure];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"->%@", [self.destination toStringHumanReadable]];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, [self.origin toStringHumanReadable], [self.destination toStringHumanReadable]];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, self.origin, self.destination];
}

@end
