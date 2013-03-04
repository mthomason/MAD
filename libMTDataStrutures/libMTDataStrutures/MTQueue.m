//
//  MTQueue.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueue.h"

@interface MTQueue ()

@property (retain) NSMutableArray *queue;
@property (assign) NSUInteger counter;

@end

@implementation MTQueue

- (void)dealloc {
    [_queue release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *queue = [[NSMutableArray alloc] init];
        [self setQueue:queue];
        [queue release];
        [self setCounter: 0];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        NSMutableArray *queue = [[NSMutableArray alloc] initWithCapacity:capacity];
        [self setQueue:queue];
        [queue release];
        [self setCounter: 0];
    }
    return self;
}

- (void)enqueue:(id)object {
    @synchronized(self) {
        [[self queue] addObject:object];
        self.counter++;
    }
}

- (void)enqueueObjectsFromArray:(NSArray *)objects {
    [[self queue] addObjectsFromArray:objects];
    [self setCounter:([self counter] + [objects count])];
}

- (id)dequeue {
    id result;
    @synchronized(self) {
        [self setCounter:([self counter] - 1)];
        result = [[[self queue] objectAtIndex:[self counter]] retain];
        [[self queue] removeObjectAtIndex:[self counter]];
        [result autorelease];
    }
    return result;
}

- (NSUInteger)count {
    return [self counter];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    return [[self queue] countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSString *)toStringHumanReadable {
    return nil;
}

- (NSString *)toString {
    return nil;
}

- (NSString *)toStringDebug {
    return nil;
}

@end