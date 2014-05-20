//
//  MTQueue.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueue.h"

@interface MTQueue ()

@property (strong) NSMutableArray *queue;
@property (assign) NSUInteger counter;

@end

@implementation MTQueue

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *queue = [[NSMutableArray alloc] init];
        [self setQueue:queue];
        [self setCounter: 0];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        NSMutableArray *queue = [[NSMutableArray alloc] initWithCapacity:capacity];
        [self setQueue:queue];
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
        result = [[self queue] objectAtIndex:[self counter]];
        [[self queue] removeObjectAtIndex:[self counter]];
    }
    return result;
}

- (NSUInteger)count {
    return [self counter];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len {
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
