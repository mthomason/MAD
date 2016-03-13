//
//  MTEdge.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

@property (nonatomic, strong) MTPair *vertices;
@property (nonatomic, strong) NSNumber *weight;
@property (readwrite, assign, getter=isDirected) bool directed;
@property (nonatomic, strong) NSNumber *uniqueIdForStructure;

@end

@implementation MTEdge

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2 {
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 andObject:nil];
}

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id <NSCopying>)object {
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 object:nil andWeight:@(1)];
}

- (instancetype)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 object:(id <NSCopying>)object andWeight:(NSNumber *)weight {
    if (self = [super initWithObject:object]) {

        _directed = true;
        
        MTPair *pair = [[MTPair alloc] initWithFormer:vertex1 andLatter:vertex2];
        self.vertices = pair;
        self.weight = weight;
        self.uniqueIdForStructure = uniqueID;
    }
    return self;
}

- (MTVertex *)origin {
    return self.vertices.former;
}

- (MTVertex *)destination {
    return self.vertices.latter;
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
    return [NSString stringWithFormat:@"->%@", [[self destination] toStringHumanReadable]];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, [[self origin] toStringHumanReadable], [[self destination] toStringHumanReadable]];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"(%@)[%@->%@]", self, [self origin], [self destination]];
}

@end
