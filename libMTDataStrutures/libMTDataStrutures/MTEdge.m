//
//  MTEdge.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTEdge.h"
#import "MTPair.h"

@interface MTEdge ()

@property (nonatomic, retain) MTPair *vertices;
@property (nonatomic, retain) NSNumber *weight;
@property (readwrite, assign) BOOL isDirected;
@property (nonatomic, retain) NSNumber *uniqueIdForStructure;

@end

@implementation MTEdge

- (void)dealloc {
    [_uniqueIdForStructure release];
    [_vertices release];
    [_weight release];
    [super dealloc];
}

- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 andDestination:(MTVertex *)vertex2 {
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 andObject:nil];
}

- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 andObject:(id)object {
    return [self initWithUniqueID:uniqueID origin:vertex1 destination:vertex2 object:nil andWeight:@(1)];
}

- (id)initWithUniqueID:(NSNumber *)uniqueID origin:(MTVertex *)vertex1 destination:(MTVertex *)vertex2 object:(id)object andWeight:(NSNumber *)weight {
    self = [super init];
    if (self) {

        [self setIsDirected:YES];
        
        MTPair *pair = [[MTPair alloc] initWithFormer:vertex1 andLatter:vertex2];
        [self setVertices:pair];
        [pair release];
        
        [self setObject: object];
        [self setWeight:weight];
        [self setUniqueIdForStructure:uniqueID];
    }
    return self;
}

- (MTVertex *)origin {
    return [[self vertices] former];
}

- (MTVertex *)destination {
    return [[self vertices] latter];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if (self == sender) {
        result = YES;
    } else {
        MTEdge *e = sender;
        result = [[self uniqueIdForStructure] isEqualToNumber:[e uniqueIdForStructure]];
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
